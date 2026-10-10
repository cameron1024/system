//! Pure event-rewriting logic, kept free of I/O so it can be unit tested.

pub const EV_REL: u16 = 0x02;
pub const REL_WHEEL: u16 = 0x08;
pub const REL_WHEEL_HI_RES: u16 = 0x0b;

/// One `v120` unit per notch, as defined by the kernel's hi-res wheel API.
const NOTCH: i32 = 120;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Event {
    pub type_: u16,
    pub code: u16,
    pub value: i32,
}

impl Event {
    pub const fn new(type_: u16, code: u16, value: i32) -> Self {
        Self { type_, code, value }
    }
}

/// With HID++ hi-res mode enabled, the mouse sends `multiplier` wheel ticks
/// per notch on the receiver's boot-mouse interface. `hid-generic` doesn't
/// know about the multiplier, so it reports every tick as a full notch
/// (`REL_WHEEL = ticks`, `REL_WHEEL_HI_RES = ticks * 120`). This undoes
/// that: hi-res values are divided by `multiplier`, and `REL_WHEEL` is
/// re-derived from the accumulated hi-res motion.
#[derive(Debug)]
pub struct Rescaler {
    multiplier: i32,
    /// Incoming hi-res units not yet converted (only non-zero if 120 isn't
    /// divisible by the multiplier).
    input_remainder: i32,
    /// Outgoing hi-res units not yet emitted as a whole `REL_WHEEL` notch.
    notch_remainder: i32,
}

impl Rescaler {
    pub fn new(multiplier: i32) -> Self {
        assert!(multiplier > 0, "multiplier must be positive");
        Self {
            multiplier,
            input_remainder: 0,
            notch_remainder: 0,
        }
    }

    /// Discard partial motion, e.g. after `SYN_DROPPED` or a reconnect.
    pub fn reset(&mut self) {
        self.input_remainder = 0;
        self.notch_remainder = 0;
    }

    /// Rewrites a single (non-SYN) event, pushing zero or more replacements
    /// onto `out`.
    pub fn process(&mut self, ev: Event, out: &mut Vec<Event>) {
        if ev.type_ != EV_REL {
            out.push(ev);
            return;
        }
        match ev.code {
            // Derived from REL_WHEEL_HI_RES below; the incoming value is a
            // raw tick count and would be `multiplier` times too fast.
            REL_WHEEL => {}
            REL_WHEEL_HI_RES => self.wheel(ev.value, out),
            _ => out.push(ev),
        }
    }

    fn wheel(&mut self, value: i32, out: &mut Vec<Event>) {
        // Like the kernel's hidpp scroll counter: don't let leftover motion
        // in one direction delay the first notch in the other.
        if value.signum() * self.notch_remainder.signum() < 0 {
            self.notch_remainder = 0;
        }
        if value.signum() * self.input_remainder.signum() < 0 {
            self.input_remainder = 0;
        }

        self.input_remainder += value;
        let hi_res = self.input_remainder / self.multiplier;
        self.input_remainder -= hi_res * self.multiplier;
        if hi_res == 0 {
            return;
        }
        out.push(Event::new(EV_REL, REL_WHEEL_HI_RES, hi_res));

        self.notch_remainder += hi_res;
        let notches = self.notch_remainder / NOTCH;
        if notches != 0 {
            self.notch_remainder -= notches * NOTCH;
            out.push(Event::new(EV_REL, REL_WHEEL, notches));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const EV_KEY: u16 = 0x01;
    const REL_X: u16 = 0x00;

    fn run(r: &mut Rescaler, events: &[Event]) -> Vec<Event> {
        let mut out = Vec::new();
        for &ev in events {
            r.process(ev, &mut out);
        }
        out
    }

    fn ticks(n: i32) -> [Event; 2] {
        [
            Event::new(EV_REL, REL_WHEEL, n),
            Event::new(EV_REL, REL_WHEEL_HI_RES, n * 120),
        ]
    }

    #[test]
    fn one_tick_is_a_fifteenth_of_a_notch() {
        let mut r = Rescaler::new(15);
        assert_eq!(
            run(&mut r, &ticks(1)),
            [Event::new(EV_REL, REL_WHEEL_HI_RES, 8)]
        );
    }

    #[test]
    fn fifteen_ticks_make_one_notch() {
        let mut r = Rescaler::new(15);
        let mut out = Vec::new();
        for _ in 0..15 {
            out.extend(run(&mut r, &ticks(1)));
        }
        let hi: i32 = out
            .iter()
            .filter(|e| e.code == REL_WHEEL_HI_RES)
            .map(|e| e.value)
            .sum();
        let lo: Vec<_> = out.iter().filter(|e| e.code == REL_WHEEL).collect();
        assert_eq!(hi, 120);
        assert_eq!(lo, [&Event::new(EV_REL, REL_WHEEL, 1)]);
    }

    #[test]
    fn batched_ticks() {
        let mut r = Rescaler::new(15);
        assert_eq!(
            run(&mut r, &ticks(-30)),
            [
                Event::new(EV_REL, REL_WHEEL_HI_RES, -240),
                Event::new(EV_REL, REL_WHEEL, -2),
            ]
        );
    }

    #[test]
    fn direction_change_drops_partial_notch() {
        let mut r = Rescaler::new(15);
        run(&mut r, &ticks(14)); // 112 of 120 towards a notch
        let out = run(&mut r, &ticks(-15));
        assert!(out.contains(&Event::new(EV_REL, REL_WHEEL, -1)));
    }

    #[test]
    fn non_divisor_multiplier_accumulates() {
        // 120 * 1 / 7 isn't whole; over 7 ticks nothing may be lost.
        let mut r = Rescaler::new(7);
        let total: i32 = (0..7)
            .flat_map(|_| run(&mut r, &ticks(1)))
            .filter(|e| e.code == REL_WHEEL_HI_RES)
            .map(|e| e.value)
            .sum();
        assert_eq!(total, 120);
    }

    #[test]
    fn other_events_pass_through() {
        let mut r = Rescaler::new(15);
        let evs = [
            Event::new(EV_REL, REL_X, -3),
            Event::new(EV_KEY, 0x110, 1),
        ];
        assert_eq!(run(&mut r, &evs), evs);
    }
}
