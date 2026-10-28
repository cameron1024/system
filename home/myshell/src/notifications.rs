//! The notification server (org.freedesktop.Notifications) and the history behind the dropdown.
//! Notifications are written to SQLite as they arrive, and are unread until acted on or marked
//! read. The dropdown pages through history in its order (unread first, then newest first).
//! `entries` is always a prefix of that order, so the next page starts after its last entry.

use std::collections::HashMap;
use std::sync::Arc;

use futures::StreamExt;
use futures::channel::mpsc;
use gpui::Context;
use gpui::EventEmitter;
use gpui::Task;
use zbus::object_server::SignalEmitter;
use zbus::zvariant::OwnedValue;

use crate::store::Key;
use crate::store::NewNotification;
pub use crate::store::Notification;
use crate::store::Store;
use crate::store::now;

const PATH: &str = "/org/freedesktop/Notifications";
const PAGE: i64 = 50;

/// NotificationClosed reasons, from the specification.
const DISMISSED: u32 = 2;
const CLOSED_BY_SENDER: u32 = 3;

/// Emitted when a notification arrives or is updated.
pub struct Arrived;

pub struct Notifications {
    entries: Vec<Notification>,
    /// In the whole history, not just `entries`.
    unread: usize,
    pub show_read: bool,
    /// The last entry ever loaded. Entries that move after it (e.g. when read) are dropped, as
    /// they'll be loaded again in their new place.
    cursor: Option<Key>,
    exhausted: bool,
    loading: bool,
    writes: mpsc::UnboundedSender<Write>,
    _server: Task<()>,
    _events: Task<()>,
}

impl EventEmitter<Arrived> for Notifications {}

enum Event {
    Added(Notification),
    Replaced(Notification, bool),
    /// Read elsewhere (e.g. by the sender); carries whether it was unread.
    Closed(i32, bool),
    Loaded(Option<Key>, Vec<Notification>),
}

/// Applied in order by one background task, so writes and page loads can't race.
enum Write {
    MarkRead(i32, i64),
    /// Every unread notification from the app with the summary.
    MarkConversationRead(String, String, i64),
    MarkAllRead(i64),
    Load(Option<Key>),
    Signal(Signal),
}

/// An XDG activation token for the click acting on a notification, once the compositor sends it.
pub type Activation = Option<futures::channel::oneshot::Receiver<String>>;

enum Signal {
    ActionInvoked(i32, String, Activation),
    Closed(i32, u32),
}

impl Notifications {
    /// `unread` is the count in the store, read in the background at startup.
    pub fn new(store: Option<Arc<Store>>, unread: usize, cx: &mut Context<Self>) -> Self {
        let (events, mut received) = mpsc::unbounded();
        let (writes, pending) = mpsc::unbounded();
        let server = match store {
            Some(store) => cx
                .background_executor()
                .spawn(serve(store, events, pending)),
            None => Task::ready(()),
        };
        let events = cx.spawn(async move |this, cx| {
            while let Some(event) = received.next().await {
                if this.update(cx, |this, cx| this.apply(event, cx)).is_err() {
                    break;
                }
            }
        });
        let mut this = Self {
            entries: Vec::new(),
            unread,
            show_read: false,
            cursor: None,
            exhausted: false,
            loading: false,
            writes,
            _server: server,
            _events: events,
        };
        this.load_more();
        this
    }

    pub fn unread(&self) -> usize {
        self.unread
    }

    /// What the dropdown lists: unread notifications, then read ones if shown.
    pub fn visible(&self) -> &[Notification] {
        if self.show_read {
            &self.entries
        } else {
            let unread = self.entries.partition_point(|entry| !entry.is_read());
            &self.entries[..unread]
        }
    }

    /// Whether there are more pages, and none is loading.
    pub fn wants_more(&self) -> bool {
        !self.loading && !self.exhausted
    }

    /// Whether every notification has been loaded.
    pub fn exhausted(&self) -> bool {
        self.exhausted
    }

    /// Loads the next page, unless one is loading or there are no more.
    pub fn load_more(&mut self) {
        if self.wants_more() {
            self.loading = true;
            self.write(Write::Load(self.cursor));
        }
    }

    pub fn toggle_show_read(&mut self, cx: &mut Context<Self>) {
        self.show_read = !self.show_read;
        cx.notify();
    }

    fn apply(&mut self, event: Event, cx: &mut Context<Self>) {
        match event {
            Event::Added(notification) => {
                self.unread += 1;
                self.entries.insert(0, notification);
                cx.emit(Arrived);
            }
            Event::Replaced(notification, was_read) => {
                self.unread += usize::from(was_read);
                self.entries.retain(|entry| entry.id != notification.id);
                // Replaced notifications are unread and newest, so first.
                self.entries.insert(0, notification);
                cx.emit(Arrived);
            }
            Event::Closed(id, was_unread) => {
                self.unread = self.unread.saturating_sub(usize::from(was_unread));
                let read_at = now();
                if let Some(entry) = self.entries.iter_mut().find(|entry| entry.id == id) {
                    entry.read_at.get_or_insert(read_at);
                }
                self.normalize();
            }
            Event::Loaded(after, page) => {
                self.loading = false;
                // A load requested before a reload (see `mark_all_read`) is stale.
                if after != self.cursor {
                    return;
                }
                self.exhausted = page.len() < PAGE as usize;
                if let Some(last) = page.last() {
                    self.cursor = Some(last.key());
                }
                self.entries.extend(page);
            }
        }
        cx.notify();
    }

    /// Restores the order after entries change state, dropping any that moved past the cursor.
    fn normalize(&mut self) {
        self.entries.sort_by_key(Notification::key);
        if !self.exhausted
            && let Some(cursor) = self.cursor
        {
            self.entries.retain(|entry| entry.key() <= cursor);
        }
    }

    fn write(&self, write: Write) {
        let _ = self.writes.unbounded_send(write);
    }

    /// Invokes the notification's action (if it has one) and marks it read. With `activation`,
    /// the sender may raise its window: many apps (e.g. Electron ones, like Slack) only do with a
    /// token.
    ///
    /// Slack doesn't close notifications once they're read, but its summary names the
    /// conversation (e.g. "[workspace] in #channel"), so the rest of the conversation's are marked
    /// read too.
    pub fn act(&mut self, id: i32, activation: Activation, cx: &mut Context<Self>) {
        let Some(entry) = self.entries.iter().find(|entry| entry.id == id) else {
            return;
        };
        if let Some(action) = entry.default_action.clone() {
            self.write(Write::Signal(Signal::ActionInvoked(id, action, activation)));
        }
        let conversation =
            (entry.app_name == "Slack").then(|| (entry.app_name.clone(), entry.summary.clone()));
        self.mark_read(id, cx);
        if let Some((app_name, summary)) = conversation {
            self.write(Write::MarkConversationRead(app_name, summary, now()));
        }
    }

    pub fn mark_read(&mut self, id: i32, cx: &mut Context<Self>) {
        let Some(entry) = self.entries.iter_mut().find(|entry| entry.id == id) else {
            return;
        };
        if entry.is_read() {
            return;
        }
        let read_at = now();
        entry.read_at = Some(read_at);
        self.unread = self.unread.saturating_sub(1);
        self.normalize();
        self.write(Write::MarkRead(id, read_at));
        self.write(Write::Signal(Signal::Closed(id, DISMISSED)));
        cx.notify();
    }

    pub fn mark_all_read(&mut self, cx: &mut Context<Self>) {
        let read_at = now();
        let mut loaded_unread = 0;
        for entry in self.entries.iter_mut().filter(|entry| !entry.is_read()) {
            entry.read_at = Some(read_at);
            loaded_unread += 1;
            let _ =
                (self.writes).unbounded_send(Write::Signal(Signal::Closed(entry.id, DISMISSED)));
        }
        self.write(Write::MarkAllRead(read_at));
        if loaded_unread < self.unread {
            // Unloaded unread notifications now sort among the loaded read ones, so the loaded
            // entries are no longer a prefix. Start again; the write above is applied first.
            self.entries.clear();
            self.cursor = None;
            self.exhausted = false;
            self.loading = false;
            self.load_more();
        } else {
            self.normalize();
        }
        self.unread = 0;
        cx.notify();
    }
}

/// Owns the bus name and applies writes. If another notification daemon owns the name, history
/// still works, but nothing new arrives.
async fn serve(
    store: Arc<Store>,
    events: mpsc::UnboundedSender<Event>,
    mut writes: mpsc::UnboundedReceiver<Write>,
) {
    let server = Server {
        store: store.clone(),
        events: events.clone(),
    };
    let connection = async {
        zbus::connection::Builder::session()?
            .name("org.freedesktop.Notifications")?
            .serve_at(PATH, server)?
            .build()
            .await
    }
    .await
    .inspect_err(|error| eprintln!("notification server unavailable: {error}"))
    .ok();
    while let Some(write) = writes.next().await {
        let result = match write {
            Write::MarkRead(id, at) => store.mark_read(id, at).map(drop),
            Write::MarkConversationRead(app_name, summary, at) => {
                let ids = store.mark_read_matching(&app_name, &summary, at);
                for &id in ids.iter().flatten() {
                    let _ = events.unbounded_send(Event::Closed(id, true));
                    if let Some(connection) = &connection
                        && let Err(error) = emit(connection, Signal::Closed(id, DISMISSED)).await
                    {
                        eprintln!("notifications: {error}");
                    }
                }
                ids.map(drop)
            }
            Write::MarkAllRead(at) => store.mark_all_read(at),
            Write::Load(after) => store.page(after, PAGE).map(|page| {
                let _ = events.unbounded_send(Event::Loaded(after, page));
            }),
            Write::Signal(signal) => match &connection {
                Some(connection) => emit(connection, signal).await,
                None => Ok(()),
            },
        };
        if let Err(error) = result {
            eprintln!("notifications: {error}");
        }
    }
}

async fn emit(connection: &zbus::Connection, signal: Signal) -> crate::data_source::Result<()> {
    let emitter = SignalEmitter::new(connection, PATH)?;
    match signal {
        Signal::ActionInvoked(id, action, activation) => {
            // The spec sends the token first. Waiting for it delays later writes, so not long.
            let token = activation.map(|token| {
                futures::future::select(
                    token,
                    Box::pin(async_io::Timer::after(std::time::Duration::from_millis(
                        200,
                    ))),
                )
            });
            if let Some(futures::future::Either::Left((Ok(token), _))) = match token {
                Some(token) => Some(token.await),
                None => None,
            } {
                Server::activation_token(&emitter, id as u32, &token).await?;
            }
            Server::action_invoked(&emitter, id as u32, &action).await?
        }
        Signal::Closed(id, reason) => {
            Server::notification_closed(&emitter, id as u32, reason).await?
        }
    }
    Ok(())
}

struct Server {
    store: Arc<Store>,
    events: mpsc::UnboundedSender<Event>,
}

#[zbus::interface(name = "org.freedesktop.Notifications")]
impl Server {
    fn get_capabilities(&self) -> Vec<&'static str> {
        vec!["body", "actions", "persistence"]
    }

    #[allow(clippy::too_many_arguments)]
    fn notify(
        &self,
        app_name: String,
        replaces_id: u32,
        app_icon: String,
        summary: String,
        body: String,
        actions: Vec<String>,
        hints: HashMap<String, OwnedValue>,
        _expire_timeout: i32,
    ) -> zbus::fdo::Result<u32> {
        let hint = |key: &str| {
            hints
                .get(key)
                .and_then(|value| <&str>::try_from(&**value).ok())
        };
        // Raw image data ("image-data") isn't supported; senders usually also give a name.
        let icon = crate::icon_theme::resolve(
            hint("image-path").or(hint("image_path")),
            &app_icon,
            hint("desktop-entry"),
            &app_name,
        );
        let failed = |error: crate::data_source::Error| zbus::fdo::Error::Failed(error.to_string());
        // Actions are (key, label) pairs; clicking invokes "default", else the only action.
        let keys: Vec<&String> = actions.iter().step_by(2).collect();
        let default_action = keys
            .iter()
            .find(|key| key.as_str() == "default")
            .or(if keys.len() == 1 { keys.first() } else { None })
            .map(|key| key.to_string());
        let new = NewNotification {
            app_name,
            app_icon,
            summary,
            body,
            default_action,
            received_at: now(),
            read_at: None,
            icon,
        };
        if replaces_id != 0
            && let Some((notification, was_read)) = (self.store)
                .replace(replaces_id as i32, &new)
                .map_err(failed)?
        {
            let _ = (self.events).unbounded_send(Event::Replaced(notification, was_read));
            return Ok(replaces_id);
        }
        let notification = self.store.insert(&new).map_err(failed)?;
        let id = notification.id as u32;
        let _ = self.events.unbounded_send(Event::Added(notification));
        Ok(id)
    }

    /// The sender no longer needs it (e.g. it was read elsewhere), so it's marked read.
    async fn close_notification(
        &self,
        id: u32,
        #[zbus(signal_emitter)] emitter: SignalEmitter<'_>,
    ) -> zbus::fdo::Result<()> {
        let was_unread = (self.store)
            .mark_read(id as i32, now())
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        let _ = (self.events).unbounded_send(Event::Closed(id as i32, was_unread));
        Self::notification_closed(&emitter, id, CLOSED_BY_SENDER).await?;
        Ok(())
    }

    fn get_server_information(&self) -> (&'static str, &'static str, &'static str, &'static str) {
        ("myshell", "myshell", env!("CARGO_PKG_VERSION"), "1.2")
    }

    #[zbus(signal)]
    async fn notification_closed(
        emitter: &SignalEmitter<'_>,
        id: u32,
        reason: u32,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn activation_token(
        emitter: &SignalEmitter<'_>,
        id: u32,
        activation_token: &str,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn action_invoked(
        emitter: &SignalEmitter<'_>,
        id: u32,
        action_key: &str,
    ) -> zbus::Result<()>;
}
