use std::time::Duration;
use std::time::Instant;

use gpui::Context;
use gpui::IntoElement;
use gpui::Render;
use gpui::Rgba;
use gpui::Window;
use gpui::div;
use gpui::prelude::*;
use gpui::relative;
use gpui::rems;
use gpui::svg;

/// Icons are 1rem, matching the bar's text size (and scaling with it). Transitions are computed
/// in these units, then applied as fractions of the slot.
const SIZE: f32 = 16.;
const DURATION: Duration = Duration::from_millis(100);

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Icon {
    Rocket,
    Leaf,
    Scales,
    Speaker,
    Muted,
    Cpu,
    Memory,
    Disk,
    Sun,
    Coffee,
    Bell,
    BellDot,
    Check,
    CheckCheck,
    History,
    BatteryEmpty,
    BatteryLow,
    BatteryMedium,
    BatteryFull,
    BatteryCharging,
    Hand,
    Mouse,
    Bluetooth,
    Slack,
    Search,
    Close,
    Sparkles,
    Apps,
    Terminal,
    Key,
    FileSearch,
    Dollar,
    Calculator,
    Smile,
    List,
    Unknown,
}

impl Icon {
    fn data(self) -> Option<&'static [u8]> {
        match self {
            Self::Rocket => Some(include_bytes!("../assets/icons/rocket.svg")),
            Self::Leaf => Some(include_bytes!("../assets/icons/leaf.svg")),
            Self::Scales => Some(include_bytes!("../assets/icons/scale.svg")),
            Self::Speaker => Some(include_bytes!("../assets/icons/volume-2.svg")),
            Self::Muted => Some(include_bytes!("../assets/icons/volume-x.svg")),
            Self::Cpu => Some(include_bytes!("../assets/icons/cpu.svg")),
            Self::Memory => Some(include_bytes!("../assets/icons/memory-stick.svg")),
            Self::Disk => Some(include_bytes!("../assets/icons/hard-drive.svg")),
            Self::Sun => Some(include_bytes!("../assets/icons/sun.svg")),
            Self::Coffee => Some(include_bytes!("../assets/icons/coffee.svg")),
            Self::Bell => Some(include_bytes!("../assets/icons/bell.svg")),
            Self::BellDot => Some(include_bytes!("../assets/icons/bell-dot.svg")),
            Self::Check => Some(include_bytes!("../assets/icons/check.svg")),
            Self::CheckCheck => Some(include_bytes!("../assets/icons/check-check.svg")),
            Self::History => Some(include_bytes!("../assets/icons/history.svg")),
            Self::BatteryEmpty => Some(include_bytes!("../assets/icons/battery.svg")),
            Self::BatteryLow => Some(include_bytes!("../assets/icons/battery-low.svg")),
            Self::BatteryMedium => Some(include_bytes!("../assets/icons/battery-medium.svg")),
            Self::BatteryFull => Some(include_bytes!("../assets/icons/battery-full.svg")),
            Self::BatteryCharging => Some(include_bytes!("../assets/icons/battery-charging.svg")),
            Self::Hand => Some(include_bytes!("../assets/icons/hand.svg")),
            Self::Mouse => Some(include_bytes!("../assets/icons/mouse.svg")),
            Self::Bluetooth => Some(include_bytes!("../assets/icons/bluetooth.svg")),
            Self::Slack => Some(include_bytes!("../assets/icons/slack.svg")),
            Self::Search => Some(include_bytes!("../assets/icons/search.svg")),
            Self::Close => Some(include_bytes!("../assets/icons/x.svg")),
            Self::Sparkles => Some(include_bytes!("../assets/icons/sparkles.svg")),
            Self::Apps => Some(include_bytes!("../assets/icons/layout-grid.svg")),
            Self::Terminal => Some(include_bytes!("../assets/icons/square-terminal.svg")),
            Self::Key => Some(include_bytes!("../assets/icons/key-round.svg")),
            Self::FileSearch => Some(include_bytes!("../assets/icons/file-search.svg")),
            Self::Dollar => Some(include_bytes!("../assets/icons/dollar-sign.svg")),
            Self::Calculator => Some(include_bytes!("../assets/icons/calculator.svg")),
            Self::Smile => Some(include_bytes!("../assets/icons/smile.svg")),
            Self::List => Some(include_bytes!("../assets/icons/list.svg")),
            Self::Unknown => None,
        }
    }
}

/// An icon that never changes, so it needs no entity or transition state.
pub fn static_icon(icon: Icon, color: Rgba) -> impl IntoElement {
    svg()
        .when_some(icon.data(), |svg, data| svg.data(data))
        .size(rems(1.))
        .flex_shrink_0()
        .text_color(color)
}

struct Layer {
    icon: Icon,
    from: f32,
    to: f32,
}

struct Motion {
    target: Icon,
    layers: Vec<Layer>,
    started: Option<Instant>,
}

impl Motion {
    fn new(target: Icon) -> Self {
        Self {
            target,
            layers: vec![Layer {
                icon: target,
                from: 0.,
                to: 0.,
            }],
            started: None,
        }
    }

    fn positions(&self, now: Instant) -> impl Iterator<Item = (Icon, f32)> + '_ {
        let t = self.started.map_or(1., |started| {
            (now.duration_since(started).as_secs_f32() / DURATION.as_secs_f32()).min(1.)
        });
        let eased = 1. - (1. - t).powi(3);
        self.layers
            .iter()
            .map(move |layer| (layer.icon, layer.from + (layer.to - layer.from) * eased))
    }

    fn change(&mut self, target: Icon, now: Instant, reduce_motion: bool) -> bool {
        if self.target == target {
            return false;
        }
        if reduce_motion {
            *self = Self::new(target);
            return true;
        }
        // Retain the visible parts of interrupted transitions, continuing all old layers down.
        self.layers = self
            .positions(now)
            .filter(|(_, y)| *y > -SIZE && *y < SIZE)
            .map(|(icon, from)| Layer {
                icon,
                from,
                to: SIZE,
            })
            .collect();
        self.layers.push(Layer {
            icon: target,
            from: -SIZE,
            to: 0.,
        });
        self.target = target;
        self.started = Some(now);
        true
    }
}

/// A fixed-size, clipped icon slot. New icons enter from above; old icons leave below.
pub struct AnimatedIcon {
    motion: Motion,
    color: Rgba,
}

impl AnimatedIcon {
    pub fn new(icon: Icon, color: Rgba) -> Self {
        Self {
            motion: Motion::new(icon),
            color,
        }
    }

    pub fn set(&mut self, icon: Icon, color: Rgba, cx: &mut Context<Self>) {
        let changed = self.motion.change(icon, Instant::now(), cx.reduce_motion());
        if changed || self.color != color {
            self.color = color;
            cx.notify();
        }
    }
}

impl Render for AnimatedIcon {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let now = Instant::now();
        if cx.reduce_motion()
            || self
                .motion
                .started
                .is_some_and(|start| now.duration_since(start) >= DURATION)
        {
            self.motion = Motion::new(self.motion.target);
        }
        if self.motion.started.is_some() {
            window.request_animation_frame();
        }
        let mut slot = div()
            .size(rems(1.))
            .flex_shrink_0()
            .relative()
            .overflow_hidden();
        for (icon, y) in self.motion.positions(now) {
            if y <= -SIZE || y >= SIZE {
                continue;
            }
            let element = match icon.data() {
                Some(data) => svg()
                    .data(data)
                    .size_full()
                    .text_color(self.color)
                    .into_any_element(),
                None => div().text_color(self.color).child("?").into_any_element(),
            };
            slot = slot.child(
                div()
                    .absolute()
                    .top(relative(y / SIZE))
                    .left_0()
                    .size_full()
                    .flex()
                    .items_center()
                    .justify_center()
                    .child(element),
            );
        }
        slot
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn icons_move_down_and_interruption_preserves_positions() {
        let now = Instant::now();
        let mut motion = Motion::new(Icon::Rocket);
        motion.change(Icon::Leaf, now, false);
        assert_eq!(
            motion.positions(now).collect::<Vec<_>>(),
            vec![(Icon::Rocket, 0.), (Icon::Leaf, -SIZE)]
        );
        let middle = now + DURATION / 2;
        let before: Vec<_> = motion.positions(middle).collect();
        assert!(before[0].1 > 0. && before[1].1 > -SIZE && before[1].1 < 0.);
        motion.change(Icon::Scales, middle, false);
        let after: Vec<_> = motion.positions(middle).collect();
        assert_eq!(&after[..2], &before);
        assert_eq!(after[2], (Icon::Scales, -SIZE));
        let end: Vec<_> = motion.positions(middle + DURATION).collect();
        assert_eq!(end.last(), Some(&(Icon::Scales, 0.)));
        assert!(end[..2].iter().all(|(_, y)| *y == SIZE));
        assert!(!motion.change(Icon::Scales, middle, false));
    }

    #[test]
    fn reduced_motion_switches_immediately() {
        let now = Instant::now();
        let mut motion = Motion::new(Icon::Speaker);
        motion.change(Icon::Muted, now, true);
        assert_eq!(
            motion.positions(now).collect::<Vec<_>>(),
            vec![(Icon::Muted, 0.)]
        );
        assert!(motion.started.is_none());
    }
}
