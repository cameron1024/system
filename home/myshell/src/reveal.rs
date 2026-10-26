//! Showing and hiding: one eased progress value per body, which drives its slide, shape, the
//! content's fade and scale, and (for the full bar) the reserved space.

use std::time::Duration;
use std::time::Instant;

const DURATION: Duration = Duration::from_millis(180);

const TWEEN: Duration = Duration::from_millis(150);

/// A value that eases to each new target from wherever it currently is (e.g. a height).
pub struct Tween {
    from: f32,
    to: f32,
    started: Instant,
    duration: Duration,
}

impl Tween {
    pub fn new(value: f32, now: Instant) -> Self {
        Self {
            from: value,
            to: value,
            started: now,
            duration: TWEEN,
        }
    }

    pub fn with_duration(self, duration: Duration) -> Self {
        Self { duration, ..self }
    }

    pub fn value(&self, now: Instant) -> f32 {
        let t =
            now.saturating_duration_since(self.started).as_secs_f32() / self.duration.as_secs_f32();
        if t >= 1. {
            return self.to;
        }
        // Cubic ease-out.
        self.from + (self.to - self.from) * (1. - (1. - t).powi(3))
    }

    pub fn set(&mut self, to: f32, now: Instant) {
        if (to - self.to).abs() > 1e-3 {
            *self = Self {
                from: self.value(now),
                to,
                started: now,
                duration: self.duration,
            };
        }
    }

    /// Jumps to `value`, e.g. while nothing using it is shown.
    pub fn snap(&mut self, value: f32, now: Instant) {
        *self = Self::new(value, now).with_duration(self.duration);
    }

    pub fn animating(&self, now: Instant) -> bool {
        self.value(now) != self.to
    }
}

/// Whether a body is shown, and its motion towards that state.
pub struct Reveal {
    pub visible: bool,
    started: Instant,
    from: f32,
    animating: bool,
}

impl Reveal {
    pub fn new(visible: bool, now: Instant) -> Self {
        Self {
            visible,
            started: now,
            from: if visible { 1. } else { 0. },
            animating: false,
        }
    }

    /// Returns false if already heading towards `visible`. Reversals start from the current
    /// position, so they never jump.
    pub fn set(&mut self, visible: bool, reduce_motion: bool, now: Instant) -> bool {
        if self.visible == visible {
            return false;
        }
        let from = self.progress(now);
        *self = Self {
            visible,
            started: now,
            from,
            animating: !reduce_motion,
        };
        true
    }

    pub fn settle(&mut self, now: Instant) {
        if self.animating && now.saturating_duration_since(self.started) >= DURATION {
            self.animating = false;
        }
    }

    pub fn animating(&self) -> bool {
        self.animating
    }

    pub fn hidden(&self) -> bool {
        !self.visible && !self.animating
    }

    /// 0 when hidden, 1 when shown.
    pub fn progress(&self, now: Instant) -> f32 {
        let to = if self.visible { 1. } else { 0. };
        if !self.animating {
            return to;
        }
        let t = now.saturating_duration_since(self.started).as_secs_f32() / DURATION.as_secs_f32();
        // Exponential ease-out: a snappy start, then a short settling tail.
        let eased = if t >= 1. { 1. } else { 1. - (-10. * t).exp2() };
        self.from + (to - self.from) * eased
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn eases_out_and_reverses_without_jumping() {
        let start = Instant::now();
        let at = |ms| start + Duration::from_millis(ms);
        let mut reveal = Reveal::new(false, start);
        reveal.set(true, false, start);
        assert_eq!(reveal.progress(start), 0.);
        assert!(reveal.progress(at(45)) > 0.8, "not snappy");
        let before = reveal.progress(at(30));
        reveal.set(false, false, at(30));
        assert_eq!(reveal.progress(at(30)), before);
        reveal.settle(at(30) + DURATION);
        assert!(reveal.hidden());
    }
}
