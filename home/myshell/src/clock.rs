//! Wall clock, updated once per minute on the minute boundary.
//!
//! GPUI timers are `CLOCK_MONOTONIC`-based, which stops during suspend, so after resume the
//! displayed time would be stale for up to a minute. Instead, a dedicated thread blocks on an
//! absolute `CLOCK_REALTIME` timerfd: it fires immediately on resume, and `TFD_TIMER_CANCEL_ON_SET`
//! wakes it early if the clock is stepped (NTP, manual set). Idle cost is one wakeup per minute.

use futures::{StreamExt, channel::mpsc};
use gpui::{Context, SharedString};
use rustix::{
    io::Errno,
    time::{
        ClockId, Itimerspec, TimerfdClockId, TimerfdFlags, TimerfdTimerFlags, Timespec,
        clock_gettime, timerfd_create, timerfd_settime,
    },
};

pub struct Clock {
    text: SharedString,
}

impl Clock {
    pub fn new(cx: &mut Context<Self>) -> Self {
        let mut ticks = minute_ticks();
        cx.spawn(async move |this, cx| {
            while ticks.next().await.is_some() {
                let updated = this.update(cx, |this, cx| {
                    this.text = format_now();
                    cx.notify();
                });
                if updated.is_err() {
                    break;
                }
            }
        })
        .detach();

        Self { text: format_now() }
    }

    pub fn text(&self) -> SharedString {
        self.text.clone()
    }
}

fn format_now() -> SharedString {
    jiff::Zoned::now().strftime("%H:%M").to_string().into()
}

fn minute_ticks() -> mpsc::UnboundedReceiver<()> {
    let (tx, rx) = mpsc::unbounded();
    std::thread::Builder::new()
        .name("clock".into())
        .stack_size(64 * 1024)
        .spawn(move || run_ticker(tx))
        .expect("failed to spawn clock thread");
    rx
}

fn run_ticker(tx: mpsc::UnboundedSender<()>) {
    let fd = timerfd_create(TimerfdClockId::Realtime, TimerfdFlags::CLOEXEC)
        .expect("failed to create timerfd");
    let flags = TimerfdTimerFlags::ABSTIME | TimerfdTimerFlags::CANCEL_ON_SET;
    let mut buf = [0u8; 8];

    loop {
        let now = clock_gettime(ClockId::Realtime);
        let next_minute = now.tv_sec - now.tv_sec.rem_euclid(60) + 60;
        let spec = Itimerspec {
            it_interval: Timespec {
                tv_sec: 0,
                tv_nsec: 0,
            },
            it_value: Timespec {
                tv_sec: next_minute,
                tv_nsec: 0,
            },
        };
        timerfd_settime(&fd, flags, &spec).expect("failed to arm timerfd");

        match rustix::io::read(&fd, &mut buf[..]) {
            // ECANCELED: the realtime clock was stepped, so refresh and re-arm.
            Ok(_) | Err(Errno::CANCELED) => {}
            Err(Errno::INTR) => continue,
            Err(err) => panic!("failed to read timerfd: {err}"),
        }

        if tx.unbounded_send(()).is_err() {
            return;
        }
    }
}
