//! Showing and hiding: one eased progress value per body, which drives its slide, shape, the
//! content's fade and scale, and (for the full bar) the reserved space.

use std::time::Duration;
use std::time::Instant;

const DURATION: Duration = Duration::from_millis(180);

const TWEEN: Duration = Duration::from_millis(150);

/// A restrained spring for island geometry, separate from bounded layout/opacity progress.
/// The body reaches its resting size early, stretches slightly, then settles exactly at one.
pub fn island_motion(progress: f32) -> f32 {
    let t = progress.clamp(0., 1.) - 1.;
    1. + 2. * t.powi(3) + t.powi(2)
}

/// A value that eases to each new target from wherever it currently is (e.g. a height).
pub struct Tween {
    from: f32,
    to: f32,
    started: Instant,
    duration: Duration,
    spring: bool,
}

impl Tween {
    pub fn new(value: f32, now: Instant) -> Self {
        Self {
            from: value,
            to: value,
            started: now,
            duration: TWEEN,
            spring: false,
        }
    }

    /// Elastic motion for geometry; fades and scroll offsets retain their bounded easing.
    pub fn spring(self) -> Self {
        Self {
            spring: true,
            ..self
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
        let eased = if self.spring {
            island_motion(t)
        } else {
            1. - (1. - t).powi(3)
        };
        self.from + (self.to - self.from) * eased
    }

    pub fn set(&mut self, to: f32, now: Instant) {
        if (to - self.to).abs() > 1e-3 {
            *self = Self {
                from: self.value(now),
                to,
                started: now,
                duration: self.duration,
                spring: self.spring,
            };
        }
    }

    /// Jumps to `value`, e.g. while nothing using it is shown.
    pub fn snap(&mut self, value: f32, now: Instant) {
        *self = Self {
            spring: self.spring,
            ..Self::new(value, now).with_duration(self.duration)
        };
    }

    pub fn animating(&self, now: Instant) -> bool {
        self.from != self.to && now.saturating_duration_since(self.started) < self.duration
    }
}

/// Whether a body is shown, and its motion towards that state.
pub struct Reveal {
    pub visible: bool,
    started: Instant,
    from: f32,
    from_linear: f32,
    animating: bool,
}

impl Reveal {
    pub fn new(visible: bool, now: Instant) -> Self {
        Self {
            visible,
            started: now,
            from: if visible { 1. } else { 0. },
            from_linear: if visible { 1. } else { 0. },
            animating: false,
        }
    }

    /// Returns false if already heading towards `visible`. Reversals start from the current
    /// position, so they never jump.
    pub fn set(&mut self, visible: bool, reduce_motion: bool, now: Instant) -> bool {
        if self.visible == visible {
            return false;
        }
        *self = Self {
            visible,
            started: now,
            from: self.progress(now),
            from_linear: self.linear(now),
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

    /// Like `progress`, but linear in time, for animations that ease themselves.
    pub fn linear(&self, now: Instant) -> f32 {
        let to = if self.visible { 1. } else { 0. };
        if !self.animating {
            return to;
        }
        let t = now.saturating_duration_since(self.started).as_secs_f32() / DURATION.as_secs_f32();
        self.from_linear + (to - self.from_linear) * t.min(1.)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn island_spring_settles_with_a_small_overshoot() {
        assert_eq!(island_motion(0.), 0.);
        assert_eq!(island_motion(1.), 1.);
        let peak = (0..=1000)
            .map(|step| island_motion(step as f32 / 1000.))
            .fold(0., f32::max);
        assert!((1.03..1.04).contains(&peak));
    }

    #[test]
    fn spring_tween_retargets_continuously_and_finishes_its_settle() {
        let start = Instant::now();
        let at = |ms| start + Duration::from_millis(ms);
        let mut tween = Tween::new(10., start).spring();
        tween.set(20., start);
        // The spring crosses its target halfway through, but still needs settling frames.
        assert_eq!(tween.value(at(75)), 20.);
        assert!(tween.animating(at(75)));
        assert!(tween.value(at(100)) > 20.);
        let before = tween.value(at(100));
        tween.set(5., at(100));
        assert_eq!(tween.value(at(100)), before);
        assert_eq!(tween.value(at(250)), 5.);
        assert!(!tween.animating(at(250)));
        tween.snap(10., at(250));
        tween.set(20., at(250));
        assert!(
            tween.value(at(350)) > 20.,
            "snap must preserve spring easing"
        );
    }

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
