//! Wall clock, updated on minute boundaries. An absolute realtime timerfd also wakes after
//! suspend and when the clock is stepped, unlike GPUI's monotonic timers. No dedicated thread.

use async_io::Async;
use futures::Stream;
use rustix::io::Errno;
use rustix::time::ClockId;
use rustix::time::Itimerspec;
use rustix::time::TimerfdClockId;
use rustix::time::TimerfdFlags;
use rustix::time::TimerfdTimerFlags;
use rustix::time::Timespec;
use rustix::time::clock_gettime;
use rustix::time::timerfd_create;
use rustix::time::timerfd_settime;

use super::DataSource;
use super::Result;

pub struct Clock;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ClockState {
    /// e.g. "09:41".
    pub time: String,
    /// e.g. "Monday 1st Jan 2025".
    pub date: String,
    /// e.g. "Monday".
    pub weekday: String,
    /// e.g. "01/01/2025".
    pub numeric_date: String,
    /// Finding the system time zone can read the time zone database, so it's done here, in the
    /// background, for the UI to use too.
    pub zone: jiff::tz::TimeZone,
}

fn format(now: &jiff::Zoned) -> ClockState {
    let day = now.day();
    let suffix = match (day % 10, day % 100) {
        (_, 11..=13) => "th",
        (1, _) => "st",
        (2, _) => "nd",
        (3, _) => "rd",
        _ => "th",
    };
    ClockState {
        time: now.strftime("%H:%M").to_string(),
        date: format!(
            "{} {day}{suffix} {}",
            now.strftime("%A"),
            now.strftime("%b %Y")
        ),
        weekday: now.strftime("%A").to_string(),
        numeric_date: now.strftime("%d/%m/%Y").to_string(),
        zone: now.time_zone().clone(),
    }
}

impl DataSource for Clock {
    type Value = ClockState;

    fn stream(self) -> impl Stream<Item = Result<ClockState>> + Send + 'static {
        async_stream::try_stream! {
            let fd = Async::new(timerfd_create(
                TimerfdClockId::Realtime,
                TimerfdFlags::CLOEXEC | TimerfdFlags::NONBLOCK,
            )?)?;
            loop {
                let now = clock_gettime(ClockId::Realtime);
                let spec = Itimerspec {
                    it_interval: Timespec { tv_sec: 0, tv_nsec: 0 },
                    it_value: Timespec {
                        tv_sec: now.tv_sec - now.tv_sec.rem_euclid(60) + 60,
                        tv_nsec: 0,
                    },
                };
                match timerfd_settime(
                    fd.get_ref(),
                    TimerfdTimerFlags::ABSTIME | TimerfdTimerFlags::CANCEL_ON_SET,
                    &spec,
                ) {
                    Ok(_) => {}
                    // A step between read and rearm can cancel settime too. Recompute the deadline.
                    Err(Errno::CANCELED) => continue,
                    Err(error) => Err(error)?,
                }
                yield format(&jiff::Zoned::now());

                let mut buf = [0; 8];
                match fd.read_with(|fd| rustix::io::read(fd, &mut buf).map_err(Into::into)).await {
                    Ok(_) => {}
                    Err(error) if error.raw_os_error() == Some(Errno::CANCELED.raw_os_error()) => {}
                    Err(error) => Err(error)?,
                }
            }
        }
    }
}
