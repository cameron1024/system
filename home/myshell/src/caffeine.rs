//! Keeps the session awake by holding a logind idle inhibitor, which idle daemons (e.g. hypridle)
//! respect. The lock lasts exactly as long as its file descriptor, so dropping it (or exiting)
//! releases it.

use gpui::Context;
use gpui::Task;
use zbus::zvariant::OwnedFd;

use crate::data_source::Result;

#[derive(Default)]
pub struct Caffeine {
    /// The requested state, shown immediately; the lock follows once logind grants it.
    pub active: bool,
    lock: Option<OwnedFd>,
    request: Option<Task<()>>,
}

impl Caffeine {
    pub fn toggle(&mut self, cx: &mut Context<Self>) {
        self.active = !self.active;
        cx.notify();
        if !self.active {
            self.lock = None;
            self.request = None;
            return;
        }
        let inhibit = cx.background_executor().spawn(inhibit());
        self.request = Some(cx.spawn(async move |this, cx| {
            let result = inhibit.await;
            let _ = this.update(cx, |this, cx| {
                match result {
                    Ok(lock) => this.lock = Some(lock),
                    Err(error) => {
                        eprintln!("caffeine: {error}");
                        this.active = false;
                        cx.notify();
                    }
                }
                this.request = None;
            });
        }));
    }
}

async fn inhibit() -> Result<OwnedFd> {
    let reply = zbus::Connection::system()
        .await?
        .call_method(
            Some("org.freedesktop.login1"),
            "/org/freedesktop/login1",
            Some("org.freedesktop.login1.Manager"),
            "Inhibit",
            &("idle", "myshell", "Caffeine", "block"),
        )
        .await?;
    Ok(reply.body().deserialize()?)
}
