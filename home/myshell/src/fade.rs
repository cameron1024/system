//! Colours fade, rather than snap, to their targets: tints that follow state, and backgrounds
//! that follow hover and selection.

use std::time::Duration;
use std::time::Instant;

use gpui::AnyElement;
use gpui::App;
use gpui::ElementId;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Pixels;
use gpui::RenderOnce;
use gpui::Rgba;
use gpui::Window;
use gpui::div;
use gpui::prelude::*;
use gpui::px;

use crate::theme;

pub const DURATION: Duration = Duration::from_millis(100);

/// A colour that fades linearly to each new target, from wherever it currently is.
pub struct Fade {
    from: Rgba,
    to: Rgba,
    started: Option<Instant>,
}

impl Fade {
    pub fn new(color: Rgba) -> Self {
        Self {
            from: color,
            to: color,
            started: None,
        }
    }

    /// Returns whether the target changed.
    pub fn set(&mut self, to: Rgba, now: Instant, reduce_motion: bool) -> bool {
        if self.to == to {
            return false;
        }
        *self = if reduce_motion {
            Self::new(to)
        } else {
            Self {
                from: self.value(now),
                to,
                started: Some(now),
            }
        };
        true
    }

    pub fn value(&self, now: Instant) -> Rgba {
        let t = self.started.map_or(1., |started| {
            (now.saturating_duration_since(started).as_secs_f32() / DURATION.as_secs_f32()).min(1.)
        });
        // A transparent end takes the other's hue, so fading in or out doesn't pass through
        // black.
        let (from, to) = match (self.from.a, self.to.a) {
            (0., _) => (Rgba { a: 0., ..self.to }, self.to),
            (_, 0.) => (self.from, Rgba { a: 0., ..self.from }),
            _ => (self.from, self.to),
        };
        let mix = |from: f32, to: f32| from + (to - from) * t;
        Rgba {
            r: mix(from.r, to.r),
            g: mix(from.g, to.g),
            b: mix(from.b, to.b),
            a: mix(from.a, to.a),
        }
    }

    pub fn animating(&self, now: Instant) -> bool {
        (self.started).is_some_and(|started| now.saturating_duration_since(started) < DURATION)
    }
}

const TRANSPARENT: Rgba = Rgba {
    r: 0.,
    g: 0.,
    b: 0.,
    a: 0.,
};

/// A colour fading to `target`, kept across frames under `key` (unique among its siblings).
/// Call while rendering.
pub fn color(key: impl Into<ElementId>, target: Rgba, window: &mut Window, cx: &mut App) -> Rgba {
    let (now, reduce_motion) = (Instant::now(), cx.reduce_motion());
    let fade = window.use_keyed_state(key, cx, |_, _| Fade::new(target));
    let (value, animating) = fade.update(cx, |fade, _| {
        fade.set(target, now, reduce_motion);
        (fade.value(now), fade.animating(now))
    });
    if animating {
        window.request_animation_frame();
    }
    value
}

/// Content built with a colour that fades to `target`, e.g. an icon tinted by state.
pub fn tinted<E: IntoElement>(
    id: impl Into<ElementId>,
    target: Rgba,
    build: impl FnOnce(Rgba) -> E + 'static,
) -> Tinted {
    Tinted {
        id: id.into(),
        target,
        build: Box::new(move |color| build(color).into_any_element()),
    }
}

#[derive(IntoElement)]
pub struct Tinted {
    id: ElementId,
    target: Rgba,
    build: Box<dyn FnOnce(Rgba) -> AnyElement>,
}

impl RenderOnce for Tinted {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        (self.build)(color(self.id, self.target, window, cx))
    }
}

/// A background that fades in while hovered, and (if given) rests at a colour, e.g. while
/// selected. It's the first child of its (positioned) container, so it's painted beneath the
/// content, and tracks hover itself without taking input from it.
pub fn background(id: impl Into<ElementId>) -> Background {
    Background {
        id: id.into(),
        rest: None,
        hover: Some(theme::MODULE_HOVER),
        radius: px(4.),
        shared: None,
    }
}

#[derive(IntoElement)]
pub struct Background {
    id: ElementId,
    rest: Option<Rgba>,
    hover: Option<Rgba>,
    radius: Pixels,
    shared: Option<(Entity<HoverFade>, ElementId)>,
}

/// Hover continuity when one visible background replaces another.
pub struct HoverFade {
    hovered: bool,
    fade: Fade,
    owner: Option<ElementId>,
}

impl HoverFade {
    pub fn new(rest: Rgba) -> Self {
        Self {
            hovered: false,
            fade: Fade::new(rest),
            owner: None,
        }
    }
}

impl Background {
    /// Only the visible copy should claim this state. Late events from the previous copy
    /// are ignored after ownership passes to its replacement.
    pub fn shared(mut self, state: Entity<HoverFade>, owner: impl Into<ElementId>) -> Self {
        self.shared = Some((state, owner.into()));
        self
    }

    pub fn rest(mut self, color: Rgba) -> Self {
        self.rest = Some(color);
        self
    }

    pub fn selected(self, selected: bool) -> Self {
        if selected {
            self.rest(theme::SELECTED)
        } else {
            self
        }
    }

    pub fn radius(mut self, radius: Pixels) -> Self {
        self.radius = radius;
        self
    }
}

impl RenderOnce for Background {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        if let Some((state, owner)) = self.shared {
            let now = Instant::now();
            let reduce_motion = cx.reduce_motion();
            let color = state.update(cx, |state, _| {
                state.owner = Some(owner.clone());
                let target = self
                    .hover
                    .filter(|_| state.hovered)
                    .or(self.rest)
                    .unwrap_or(TRANSPARENT);
                state.fade.set(target, now, reduce_motion);
                if state.fade.animating(now) {
                    window.request_animation_frame();
                }
                state.fade.value(now)
            });
            return div()
                .id(self.id)
                .absolute()
                .inset_0()
                .rounded(self.radius)
                .bg(color)
                .on_hover(move |is_hovered, _, cx| {
                    state.update(cx, |state, cx| {
                        if state.owner.as_ref() == Some(&owner) && state.hovered != *is_hovered {
                            state.hovered = *is_hovered;
                            cx.notify();
                        }
                    });
                });
        }
        let (hovered, color) = window.with_element_namespace(self.id.clone(), |window| {
            let hovered = window.use_keyed_state("hovered", cx, |_, _| false);
            let target = (self.hover)
                .filter(|_| *hovered.read(cx))
                .or(self.rest)
                .unwrap_or(TRANSPARENT);
            (hovered, color("color", target, window, cx))
        });
        div()
            .id(self.id)
            .absolute()
            .inset_0()
            .rounded(self.radius)
            .bg(color)
            .when(self.hover.is_some(), |background| {
                background.on_hover(move |is_hovered, _, cx| {
                    hovered.update(cx, |hovered, cx| {
                        *hovered = *is_hovered;
                        cx.notify();
                    });
                })
            })
    }
}
