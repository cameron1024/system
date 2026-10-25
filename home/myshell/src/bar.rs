use std::cell::Cell;
use std::cell::RefCell;
use std::ops::Range;
use std::rc::Rc;
use std::time::Duration;
use std::time::Instant;

use futures::channel::mpsc;

use gpui::Bounds;

use gpui::Context;
use gpui::Div;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Pixels;

use gpui::AnyElement;
use gpui::App;
use gpui::Render;
use gpui::Rgba;
use gpui::ScrollWheelEvent;
use gpui::Stateful;
use gpui::Window;
use gpui::canvas;
use gpui::div;
use gpui::prelude::*;
use gpui::px;
use gpui::rems;
use gpui::uniform_list;

use crate::animated_icon::Icon;
use crate::animated_icon::static_icon;
use crate::bar_module::Module;
use crate::bar_module::bar_module;
use crate::battery_indicator::BatteryIndicator;
use crate::blur::Blur;
use crate::data_source::Data;
use crate::data_source::DataSource;
use crate::liquid;
use crate::notifications::Notification;
use crate::profile_icon::ProfileIcon;
use crate::reveal::Reveal;
use crate::scaled::scaled;
use crate::shell::Sources;
use crate::theme;
use crate::tooltip::text_tooltip;

type TooltipBuilder = Box<dyn Fn(&mut Window, &mut gpui::App) -> gpui::AnyView>;
use crate::volume_button::VolumeButton;

pub const HEIGHT: f32 = 36.;
/// Space between a section's (or peeked module's) edge and the liquid around it at rest.
const BLOB_PAD_X: f32 = 12.;
/// Keeps the outer sections' flares on screen at rest.
const EDGE_MARGIN: f32 = BLOB_PAD_X + liquid::FLARE + 2.;
/// A revealing body starts at this fraction of its width, and widens as it drops.
const START_WIDTH: f32 = 0.4;
/// Content scales in from this size as it fades in.
const START_SCALE: f32 = 0.9;
/// Liquid above and below a module.
const PAD_Y: f32 = (HEIGHT - crate::bar_module::HEIGHT) / 2.;

/// The notifications dropdown. Rows have fixed heights, so its height is known before layout
/// and can be animated.
const DROPDOWN_WIDTH: f32 = 360.;
const ROW_HEIGHT: f32 = 70.;
/// Between rows; also holds the separator between unread and read notifications.
const ROW_GAP: f32 = 8.;
/// Rendering a row this close to the end of the loaded notifications loads more.
const LOAD_AHEAD: usize = 25;
/// Inside the dropdown, around its controls and list.
const LIST_PAD: f32 = 12.;
/// Matches the liquid's margin at the sides (BLOB_PAD_X + LIST_PAD) to its margin at the bottom.
const LIST_PAD_BOTTOM: f32 = BLOB_PAD_X + LIST_PAD - PAD_Y;
const MAX_LIST_HEIGHT: f32 = 480.;

fn list_height(rows: f32) -> f32 {
    // The empty state takes one row.
    let rows = rows.max(1.);
    (rows * (ROW_HEIGHT + ROW_GAP) - ROW_GAP + LIST_PAD + LIST_PAD_BOTTOM).min(MAX_LIST_HEIGHT)
}

/// A body of liquid behind some content, `height` tall at rest and `progress` of the way
/// through being revealed.
#[derive(Clone, Copy)]
struct Body {
    left: f32,
    right: f32,
    height: f32,
    progress: f32,
    /// Joins a bar-height body on its left with a concave fillet.
    fillet: bool,
}

/// While revealing, a body starts narrow and bump-shaped (each side's flare and rounded bottom
/// are equal quarter-ellipses, approximating a cosine), then widens and morphs into its resting
/// shape as it drops.
fn blob(body: Body) -> Option<liquid::Outline> {
    let progress = body.progress.clamp(0., 1.);
    let bottom = body.height * progress;
    let centre = (body.left + body.right) / 2.;
    let rest_half = (body.right - body.left) / 2. + BLOB_PAD_X;
    let half = rest_half * (START_WIDTH + (1. - START_WIDTH) * progress);
    // From the bump (at 0) to the resting shape (at 1).
    let morph = |bump: f32, rest: f32| bump + (rest - bump) * progress;
    let flare_x = morph(half, liquid::FLARE);
    let flare_y = morph(bottom / 2., liquid::FLARE.min(bottom / 2.));
    let radius_y = (bottom / 2.).min(HEIGHT / 2.);
    // A cosine's steepest run per unit of drop is 2 * width / (pi * height). Easing it to
    // vertical as the body settles gives the resting shape's straight sides.
    let slope = 2. * (flare_x + half) / (std::f32::consts::PI * bottom) * (1. - progress);
    let inset = slope * (bottom - radius_y - flare_y);
    liquid::outline(
        centre - half,
        centre + half,
        bottom,
        liquid::Corners {
            flare_x,
            flare_y,
            radius_x: morph(half, HEIGHT / 2.).min(half - inset).max(0.),
            radius_y,
            slope,
        },
    )
}

/// For a body taller than the bar, joined on its left to the bar-height body beside it.
fn fillet(body: Body) -> Option<liquid::Outline> {
    let progress = body.progress.clamp(0., 1.);
    let neighbour_bottom = HEIGHT * progress;
    let radius = liquid::FLARE.min((body.height * progress - neighbour_bottom) / 2.);
    if !body.fillet || radius < 0.5 {
        return None;
    }
    // Matches blob's left side.
    let centre = (body.left + body.right) / 2.;
    let half = ((body.right - body.left) / 2. + BLOB_PAD_X)
        * (START_WIDTH + (1. - START_WIDTH) * progress);
    Some(liquid::fillet(centre - half, neighbour_bottom, radius))
}

/// How far the content row is slid up out of view.
fn slide_offset(progress: f32) -> f32 {
    -HEIGHT * (1. - progress)
}

pub struct Bar {
    sources: Sources,
    profile_icon: Entity<ProfileIcon>,
    volume_button: Entity<VolumeButton>,
    battery: Entity<BatteryIndicator>,
    actions: mpsc::UnboundedSender<ModuleAction>,
    scroll_remainder: f32,
    bar: Reveal,
    /// Modules shown on their own while the bar is hidden, each with its own animation.
    peeks: Vec<(Module, Reveal)>,
    /// The bar's and each peek's progress for the frame being rendered.
    bar_progress: f32,
    peek_progress: Vec<(Module, f32)>,
    /// Written by each section (or peeked module) during prepaint, then read when painting
    /// the liquid behind them.
    liquid: Rc<RefCell<Vec<Body>>>,
    /// Blur behind the liquid, if the compositor supports it. Created on the first frame.
    blur: Option<Rc<RefCell<Option<Blur>>>>,
    reserved_space: i32,
    dropdown: Reveal,
    dropdown_progress: f32,
    /// The notifications island's bounds, recorded during prepaint for the input region.
    island: Rc<Cell<Option<Bounds<Pixels>>>>,
    surface_height: f32,
    removals: Vec<Removal>,
}

pub enum ModuleAction {
    Click(Module),
    Adjust(Module, i32),
    Notifications(NotificationAction),
}

#[derive(Clone, Copy)]
pub enum NotificationAction {
    MarkAllRead,
    ToggleShowRead,
    LoadMore,
}

impl Bar {
    pub fn set_visible(&mut self, visible: bool, window: &mut Window, cx: &mut Context<Self>) {
        // The full bar includes every module, so it replaces any peeks.
        self.peeks.clear();
        let (reduce_motion, now) = (cx.reduce_motion(), Instant::now());
        if self.bar.set(visible, reduce_motion, now) {
            self.scroll_remainder = 0.;
            // Until the next frame, neither stale nor newly revealed content accepts clicks.
            window.set_input_region(Some(&[]));
        }
        cx.notify();
    }

    pub fn set_dropdown(&mut self, open: bool, cx: &mut Context<Self>) {
        self.dropdown.set(open, cx.reduce_motion(), Instant::now());
        cx.notify();
    }

    pub fn peek(&mut self, module: Module, cx: &mut Context<Self>) {
        let (reduce_motion, now) = (cx.reduce_motion(), Instant::now());
        match self.peeks.iter_mut().find(|(peeked, _)| *peeked == module) {
            Some((_, reveal)) => {
                reveal.set(true, reduce_motion, now);
            }
            None => {
                let mut reveal = Reveal::new(false, now);
                reveal.set(true, reduce_motion, now);
                self.peeks.push((module, reveal));
            }
        }
        cx.notify();
    }

    pub fn hide_peek(&mut self, module: Module, cx: &mut Context<Self>) {
        let reduce_motion = cx.reduce_motion();
        if let Some((_, reveal)) = self.peeks.iter_mut().find(|(peeked, _)| *peeked == module) {
            reveal.set(false, reduce_motion, Instant::now());
            cx.notify();
        }
    }

    /// Whether anything is on screen, including animations.
    fn shown(&self) -> bool {
        !self.bar.hidden() || !self.peeks.is_empty() || !self.dropdown.hidden()
    }

    pub fn new(
        sources: Sources,
        actions: mpsc::UnboundedSender<ModuleAction>,
        cx: &mut Context<Self>,
    ) -> Self {
        // Modules without their own view are rendered inline from these sources.
        redraw_on(&sources.clock, cx);
        redraw_on(&sources.system, cx); // CPU, memory and disk
        redraw_on(&sources.brightness, cx);
        redraw_on(&sources.caffeine, cx);
        redraw_on(&sources.notifications, cx);
        let power = sources.power.clone();
        let volume = sources.volume.clone();
        let battery = sources.battery.clone();

        Self {
            sources,
            profile_icon: cx.new(|cx| ProfileIcon::new(power, cx)),
            volume_button: cx.new(|cx| VolumeButton::new(volume, cx)),
            battery: cx.new(|cx| BatteryIndicator::new(battery, cx)),
            actions,
            scroll_remainder: 0.,
            bar: Reveal::new(true, Instant::now()),
            peeks: Vec::new(),
            bar_progress: 1.,
            peek_progress: Vec::new(),
            liquid: Rc::default(),
            blur: None,
            reserved_space: HEIGHT as i32,
            dropdown: Reveal::new(false, Instant::now()),
            dropdown_progress: 0.,
            island: Rc::default(),
            surface_height: HEIGHT,
            removals: Vec::new(),
        }
    }

    /// Content fades and scales in as it's revealed. While peeking, other modules keep their
    /// layout space so the peeked one doesn't move.
    fn module(&self, module: Module, content: impl IntoElement, accent: Rgba) -> Stateful<Div> {
        let peeked = (self.peek_progress.iter()).find(|(peeked, _)| *peeked == module);
        let progress = match peeked {
            _ if !self.bar.hidden() => self.bar_progress,
            Some(&(_, progress)) => progress,
            None => 0.,
        };
        let scale = START_SCALE + (1. - START_SCALE) * progress;
        let element = bar_module(module.name(), scaled(scale, content), accent)
            .flex_shrink_0()
            .opacity(progress);
        match peeked {
            _ if !self.bar.hidden() => element,
            // Offset visually only, so neighbours never move.
            Some(&(_, progress)) => element
                .relative()
                .top(px(slide_offset(progress)))
                .child(self.liquid_anchor(progress, None, false)),
            None => element.invisible(),
        }
    }

    /// A group of modules with separators between them, sharing one body of liquid unless
    /// modules are peeking.
    fn section<const N: usize>(&self, modules: [Stateful<Div>; N]) -> Div {
        let peeking = self.bar.hidden();
        // Top-aligned, so a dropdown in the section grows downwards without moving the rest.
        let mut section = div()
            .flex()
            .items_start()
            .gap_1()
            .when(!peeking, |section| {
                // Always bar-height: a dropdown's taller body joins it with a fillet.
                section.child(self.liquid_anchor(self.bar_progress, Some(HEIGHT), false))
            });
        for (index, module) in modules.into_iter().enumerate() {
            if index > 0 {
                // Kept in layout while peeking, so peeked modules don't move.
                section = section.child(
                    div()
                        .w(px(1.))
                        .h(px(14.))
                        .mt(px((crate::bar_module::HEIGHT - 14.) / 2.))
                        .flex_shrink_0()
                        .bg(theme::SEPARATOR)
                        .opacity(self.bar_progress)
                        .when(peeking, |separator| separator.invisible()),
                );
            }
            section = section.child(module);
        }
        section
    }

    /// Records its parent's horizontal bounds, so a body `progress` of the way through being
    /// revealed can be painted behind it. Its height is `height`, or else the parent's. With
    /// `fillet`, its left side joins a bar-height body beside it smoothly.
    fn liquid_anchor(&self, progress: f32, height: Option<f32>, fillet: bool) -> impl IntoElement {
        let liquid = self.liquid.clone();
        canvas(
            move |bounds, _, _| {
                liquid.borrow_mut().push(Body {
                    left: f32::from(bounds.left()),
                    right: f32::from(bounds.right()),
                    height: height.unwrap_or(f32::from(bounds.size.height) + 2. * PAD_Y),
                    progress,
                    fillet,
                })
            },
            |_, _, _, _| {},
        )
        .absolute()
        .inset_0()
    }

    fn clickable(element: Stateful<Div>, module: Module, cx: &mut Context<Self>) -> Stateful<Div> {
        element
            .cursor_pointer()
            .on_click(cx.listener(move |this, _, _, _| {
                let _ = this.actions.unbounded_send(ModuleAction::Click(module));
            }))
    }

    fn adjustable(element: Stateful<Div>, module: Module, cx: &mut Context<Self>) -> Stateful<Div> {
        element.on_scroll_wheel(cx.listener(move |this, event: &ScrollWheelEvent, _, cx| {
            // Accumulate smooth touchpad deltas; one line/notch is one step.
            this.scroll_remainder += f32::from(event.delta.pixel_delta(px(24.)).y) / 24.;
            let steps = this.scroll_remainder.trunc() as i32;
            this.scroll_remainder -= steps as f32;
            if steps != 0 {
                let _ = this
                    .actions
                    .unbounded_send(ModuleAction::Adjust(module, steps));
            }
            cx.stop_propagation();
        }))
    }
}

impl Bar {
    /// The notifications module, which grows into a dropdown. Its controls take the space the
    /// rest of the section slides out of.
    fn notifications_island(&self, cx: &mut Context<Self>) -> Stateful<Div> {
        let peek = (self.peek_progress.iter())
            .find(|(module, _)| *module == Module::Notifications)
            .map(|&(_, progress)| progress);
        let progress = if self.bar.hidden() {
            peek.unwrap_or(0.).max(self.dropdown_progress)
        } else {
            self.bar_progress
        };
        let shown = !self.bar.hidden() || peek.is_some() || !self.dropdown.hidden();
        let dropdown = self.dropdown_progress;

        let notifications = self.sources.notifications.read(cx);
        let unread = notifications.unread();

        let show_read = notifications.show_read;
        let color = if unread > 0 {
            theme::NOTIFICATION_ACCENT
        } else {
            theme::MUTED
        };
        let bell = div()
            .flex()
            .items_center()
            .gap_1()
            .text_color(color)
            .child(static_icon(
                if unread > 0 {
                    Icon::BellDot
                } else {
                    Icon::Bell
                },
                color,
            ))
            .when(unread > 0, |bell| bell.child(unread.to_string()));
        let scale = START_SCALE + (1. - START_SCALE) * progress;
        let bell = bar_module(Module::Notifications.name(), scaled(scale, bell), color)
            .flex_shrink_0()
            .when(self.dropdown.visible, |bell| bell.bg(theme::SELECTED));
        let bell = Self::clickable(bell, Module::Notifications, cx);
        let header = div()
            .flex()
            .items_center()
            .justify_between()
            .min_w(px(DROPDOWN_WIDTH * dropdown))
            .when(dropdown > 0., |header| {
                header.child(
                    div()
                        .flex()
                        .items_center()
                        .gap_1()
                        .pl(px(LIST_PAD))
                        .opacity(dropdown)
                        .child(self.control(
                            "show-read",
                            Icon::History,
                            show_read,
                            NotificationAction::ToggleShowRead,
                            cx,
                        ))
                        .child(self.control(
                            "mark-all-read",
                            Icon::CheckCheck,
                            false,
                            NotificationAction::MarkAllRead,
                            cx,
                        )),
                )
            })
            .child(bell);

        let rows = self.list_rows(Instant::now(), cx);
        let island = self.island.clone();
        div()
            .id("notifications-island")
            // Room between the controls and the module before them.
            .ml(px(LIST_PAD * dropdown))
            .flex()
            .flex_col()
            .items_end()
            .overflow_hidden()
            .h(px(crate::bar_module::HEIGHT + list_height(rows) * dropdown))
            .opacity(progress)
            .child(header)
            .when(dropdown > 0., |this| {
                // Clipped to the animated width; the list itself stays full width.
                this.child(
                    div()
                        .w(px(DROPDOWN_WIDTH * dropdown))
                        .flex()
                        .justify_end()
                        .overflow_hidden()
                        .child(self.notification_list(cx)),
                )
            })
            // Offset visually only, like other peeked modules.
            .when(self.bar.hidden(), |this| {
                this.relative().top(px(slide_offset(progress)))
            })
            .map(|this| {
                if shown {
                    // Joined to the right section's body, unless peeking on its own.
                    let fillet = !self.bar.hidden();
                    this.child(self.liquid_anchor(progress, None, fillet))
                        .child(
                            canvas(
                                move |bounds, _, _| island.set(Some(bounds)),
                                |_, _, _, _| {},
                            )
                            .absolute()
                            .inset_0(),
                        )
                } else {
                    this.invisible()
                }
            })
    }

    /// An icon button in the dropdown, tinted while `selected`.
    fn control(
        &self,
        id: &'static str,
        icon: Icon,
        selected: bool,
        action: NotificationAction,
        cx: &mut Context<Self>,
    ) -> Stateful<Div> {
        let color = if selected {
            theme::NOTIFICATION_ACCENT
        } else {
            theme::FOREGROUND
        };
        div()
            .id(id)
            .size(px(crate::bar_module::HEIGHT))
            .flex()
            .items_center()
            .justify_center()
            .rounded(px(4.))
            .cursor_pointer()
            .hover(|button| button.bg(theme::MODULE_HOVER))
            .when(selected, |button| button.bg(theme::SELECTED))
            .child(static_icon(icon, color))
            .on_click(cx.listener(move |this, _, _, _| {
                let _ = (this.actions).unbounded_send(ModuleAction::Notifications(action));
            }))
    }

    /// Rows the dropdown is sized for, including gaps still collapsing after removals.
    fn list_rows(&self, now: Instant, cx: &App) -> f32 {
        let visible = self.sources.notifications.read(cx).visible().len() as f32;
        let collapsing: f32 = (self.removals.iter())
            .filter(|removal| !removal.reappears)
            .map(|removal| removal.gap(now) / (ROW_HEIGHT + ROW_GAP))
            .sum();
        visible + collapsing
    }

    /// Marks an unread notification read (and optionally acts on it), animating it out. The
    /// change applies before the next frame, so the next row's click targets are already where
    /// this one's were: rapid clicks never miss.
    fn remove(&mut self, id: i32, act: bool, cx: &mut Context<Self>) {
        let notifications = self.sources.notifications.read(cx);
        let visible = notifications.visible();
        let Some(index) = visible.iter().position(|entry| entry.id == id) else {
            return;
        };
        let notification = visible[index].clone();
        let reappears = notifications.show_read;
        if !notification.is_read() {
            // Gaps below the removed row now sit one row higher.
            for removal in &mut self.removals {
                if removal.index > index {
                    removal.index -= 1;
                }
            }
            self.removals.push(Removal {
                index,
                notification,
                started: Instant::now(),
                reappears,
            });
        }
        (self.sources.notifications).update(cx, |notifications, cx| {
            if act {
                notifications.act(id, cx)
            } else {
                notifications.mark_read(id, cx)
            }
        });
        if act {
            // Acting usually focuses the sender, so close the dropdown.
            let _ = (self.actions).unbounded_send(ModuleAction::Click(Module::Notifications));
        }
        cx.notify();
    }

    /// Only visible rows are rendered. Rendering a row within `LOAD_AHEAD` of the end loads
    /// the next page.
    fn notification_list(&self, cx: &mut Context<Self>) -> AnyElement {
        let now = Instant::now();
        let notifications = self.sources.notifications.read(cx);
        let visible = notifications.visible().len();
        let height = px(list_height(self.list_rows(now, cx)));
        if visible == 0 && self.removals.is_empty() {
            return div()
                .flex_shrink_0()
                .w(px(DROPDOWN_WIDTH))
                .h(height)
                .flex()
                .items_center()
                .justify_center()
                .text_size(px(14.))
                .text_color(theme::MUTED)
                .child(if notifications.show_read {
                    "No notifications"
                } else {
                    "No unread notifications"
                })
                .into_any_element();
        }
        // Rows past the end host the ghosts of removed last rows.
        let count = (self.removals.iter())
            .map(|removal| removal.index + 1)
            .fold(visible, usize::max);
        uniform_list(
            "notification-list",
            count,
            cx.processor(|this, range: Range<usize>, _, cx| {
                let now = Instant::now();
                let timestamp = jiff::Timestamp::now();
                let notifications = this.sources.notifications.read(cx);
                let visible = notifications.visible();
                if range.end + LOAD_AHEAD >= visible.len() && notifications.wants_more() {
                    let action = ModuleAction::Notifications(NotificationAction::LoadMore);
                    let _ = this.actions.unbounded_send(action);
                }
                let first_read = visible.partition_point(|entry| !entry.is_read());
                // Cloned, as rows need `cx` for their listeners.
                let rows: Vec<Option<Notification>> = range
                    .clone()
                    .map(|index| visible.get(index).cloned())
                    .collect();
                (rows.into_iter().zip(range))
                    .map(|(notification, index)| {
                        let separated = index == first_read && index > 0;
                        this.notification_row(notification, index, separated, now, timestamp, cx)
                    })
                    .collect::<Vec<_>>()
            }),
        )
        .flex_shrink_0()
        .w(px(DROPDOWN_WIDTH))
        .h(height)
        .px(px(LIST_PAD))
        .pt(px(LIST_PAD - ROW_GAP))
        .pb(px(LIST_PAD_BOTTOM))
        .into_any_element()
    }

    /// A uniform-height slot, with click targets at its real position. Cards are drawn offset
    /// by the gaps of removals above, which close after the removed rows swipe away.
    fn notification_row(
        &self,
        notification: Option<Notification>,
        index: usize,
        separated: bool,
        now: Instant,
        timestamp: jiff::Timestamp,
        cx: &mut Context<Self>,
    ) -> Stateful<Div> {
        // Each removal is drawn where it was: below the gaps of those before it.
        let ghosts = (self.removals.iter())
            .filter(|removal| removal.index == index)
            .map(|removal| {
                let above: f32 = (self.removals.iter())
                    .filter(|other| {
                        other.index < removal.index
                            || other.index == removal.index && other.started < removal.started
                    })
                    .map(|other| other.gap(now))
                    .sum();
                let swipe = removal.swipe(now);
                notification_card(&removal.notification, timestamp, Tick::Icon)
                    .absolute()
                    .top(px(ROW_GAP + above))
                    .left(px(DROPDOWN_WIDTH * 0.4 * swipe))
                    .w(px(DROPDOWN_WIDTH - 2. * LIST_PAD))
                    .opacity(1. - swipe)
            })
            .collect::<Vec<_>>();
        let slot = div().h(px(ROW_HEIGHT + ROW_GAP)).w_full().relative();
        let Some(notification) = notification else {
            return slot.id(("notification-ghost", index)).children(ghosts);
        };
        let offset: f32 = (self.removals.iter())
            .filter(|removal| removal.index <= index)
            .map(|removal| removal.gap(now))
            .sum();
        let id = notification.id;
        let read = notification.is_read();
        let card = notification_card(
            &notification,
            timestamp,
            if read { Tick::None } else { Tick::Space },
        )
        .absolute()
        .top(px(ROW_GAP + offset))
        .left_0()
        .right_0()
        .group_hover("notification", |card| card.bg(theme::MODULE_HOVER))
        // Read notifications are greyed out.
        .when(read, |card| card.opacity(0.55));
        slot.id(("notification", id as usize))
            .group("notification")
            .cursor_pointer()
            .when(separated, |slot| {
                slot.child(
                    div()
                        .absolute()
                        .top(px(ROW_GAP / 2. + offset))
                        .left(px(8.))
                        .right(px(8.))
                        .h(px(1.))
                        .bg(theme::SEPARATOR),
                )
            })
            .child(card)
            .when(!read, |slot| {
                slot.child(
                    div()
                        .id(("mark-read", id as usize))
                        .group("notification-tick")
                        .absolute()
                        .top(px(ROW_GAP + (ROW_HEIGHT - TICK) / 2.))
                        .right(px(TICK_INSET))
                        .size(px(TICK))
                        .child(
                            tick()
                                .relative()
                                .top(px(offset))
                                .group_hover("notification-tick", |tick| {
                                    tick.bg(theme::MODULE_HOVER)
                                }),
                        )
                        .on_click(cx.listener(move |this, _, _, cx| {
                            // The tick is inside the row, which would otherwise act too.
                            cx.stop_propagation();
                            this.remove(id, false, cx);
                        })),
                )
            })
            .children(ghosts)
            .on_click(cx.listener(move |this, _, _, cx| this.remove(id, true, cx)))
    }
}

const SWIPE: Duration = Duration::from_millis(120);
const COLLAPSE: Duration = Duration::from_millis(120);
const TICK: f32 = 28.;
const TICK_INSET: f32 = 10.;

/// A notification marked read: it swipes right and fades, then the gap it leaves closes.
struct Removal {
    /// Its gap sits above the visible notification at this index.
    index: usize,
    notification: Notification,
    started: Instant,
    /// It moves to the read section rather than disappearing.
    reappears: bool,
}

impl Removal {
    fn phase(&self, now: Instant, delay: Duration, duration: Duration) -> f32 {
        let elapsed = now
            .saturating_duration_since(self.started)
            .saturating_sub(delay);
        let t = (elapsed.as_secs_f32() / duration.as_secs_f32()).min(1.);
        // Cubic ease-out.
        1. - (1. - t).powi(3)
    }

    fn swipe(&self, now: Instant) -> f32 {
        self.phase(now, Duration::ZERO, SWIPE)
    }

    /// The space it still occupies.
    fn gap(&self, now: Instant) -> f32 {
        (ROW_HEIGHT + ROW_GAP) * (1. - self.phase(now, SWIPE, COLLAPSE))
    }

    fn done(&self, now: Instant) -> bool {
        now.saturating_duration_since(self.started) >= SWIPE + COLLAPSE
    }
}

/// The tick's visual; its click target is separate (see `notification_row`).
fn tick() -> Div {
    div()
        .size(px(TICK))
        .flex()
        .items_center()
        .justify_center()
        .rounded(px(4.))
        .child(static_icon(Icon::Check, theme::MUTED))
}

enum Tick {
    None,
    /// Room for a tick drawn separately.
    Space,
    Icon,
}

/// A notification's visuals, without click targets.
fn notification_card(notification: &Notification, now: jiff::Timestamp, tick_: Tick) -> Div {
    // Notification text is plain (no body-markup capability), but may span lines.
    let line = |text: &str| text.replace('\n', " ");
    let text = div()
        .flex_1()
        .min_w_0()
        .flex()
        .flex_col()
        .justify_center()
        .child(
            div()
                .flex()
                .justify_between()
                .gap_2()
                .text_size(px(12.))
                .text_color(theme::MUTED)
                .child(div().truncate().child(line(&notification.app_name)))
                .child(
                    div()
                        .flex_shrink_0()
                        .child(relative_time(notification.received_at, now)),
                ),
        )
        .child(
            div()
                .truncate()
                .text_size(px(14.))
                .text_color(theme::FOREGROUND)
                .child(line(&notification.summary)),
        )
        .when(!notification.body.is_empty(), |text| {
            text.child(
                div()
                    .truncate()
                    .text_size(px(13.))
                    .text_color(theme::palette::GREY2)
                    .child(line(&notification.body)),
            )
        });
    div()
        .h(px(ROW_HEIGHT))
        .pl_2p5()
        .pr(px(TICK_INSET))
        .rounded(px(8.))
        .flex()
        .items_center()
        .gap_2()
        .bg(theme::CARD)
        .child(text)
        .map(|card| match tick_ {
            Tick::None => card,
            Tick::Space => card.child(div().flex_shrink_0().size(px(TICK))),
            Tick::Icon => card.child(tick()),
        })
}

/// e.g. "now", "5m ago", "3h ago", "Oct 22".
fn relative_time(received_at: i64, now: jiff::Timestamp) -> String {
    let Ok(received) = jiff::Timestamp::from_millisecond(received_at) else {
        return String::new();
    };
    let minutes = (now.as_second() - received.as_second()) / 60;
    match minutes {
        ..1 => "now".into(),
        1..60 => format!("{minutes}m ago"),
        60..1440 => format!("{}h ago", minutes / 60),
        _ => received
            .to_zoned(jiff::tz::TimeZone::system())
            .strftime("%b %-d")
            .to_string(),
    }
}

fn redraw_on<T: 'static>(entity: &Entity<T>, cx: &mut Context<Bar>) {
    cx.observe(entity, |this, _, cx| {
        if this.shown() {
            cx.notify();
        }
    })
    .detach();
}

fn labelled(icon: Icon, color: Rgba, label: String) -> Div {
    div()
        .flex()
        .items_center()
        .gap_1()
        .text_color(color)
        .child(static_icon(icon, color))
        .child(label)
}

impl Render for Bar {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let now = Instant::now();
        self.bar.settle(now);
        for (_, reveal) in &mut self.peeks {
            reveal.settle(now);
        }
        self.peeks.retain(|(_, reveal)| !reveal.hidden());
        self.peek_progress = (self.peeks.iter())
            .map(|(module, reveal)| (*module, reveal.progress(now)))
            .collect();
        self.bar_progress = self.bar.progress(now);
        self.dropdown.settle(now);
        self.dropdown_progress = self.dropdown.progress(now);

        // The surface grows to fit the dropdown while it's shown. Its transparent remainder
        // passes input through, and the reserved space is set separately.
        let surface_height = if self.dropdown.hidden() {
            HEIGHT
        } else {
            HEIGHT + MAX_LIST_HEIGHT
        };
        if self.surface_height != surface_height {
            let width = window.viewport_size().width;
            window.resize(gpui::size(width, px(surface_height)));
            self.surface_height = surface_height;
        }

        // Layer-shell exclusive zones are whole logical pixels, so this only commits when the
        // rounded height changes.
        let reserved_space = (HEIGHT * self.bar_progress).round() as i32;
        if self.reserved_space != reserved_space {
            window.set_exclusive_zone(px(reserved_space as f32));
            self.reserved_space = reserved_space;
        }
        self.removals.retain(|removal| !removal.done(now));
        if self.bar.animating()
            || self.dropdown.animating()
            || !self.removals.is_empty()
            || self.peeks.iter().any(|(_, reveal)| reveal.animating())
        {
            window.request_animation_frame();
        }
        let blur = (self.blur)
            .get_or_insert_with(|| Rc::new(RefCell::new(Blur::new(window))))
            .clone();
        if !self.shown() {
            window.set_input_region(Some(&[]));
            if let Some(blur) = blur.borrow_mut().as_mut() {
                blur.set_region(Vec::new());
            }
            return div().size_full().into_any_element();
        }
        // Set while painting, once the island's bounds are known.
        let input_bar = self.bar.visible;
        let input_island = self.dropdown.visible;
        let island = self.island.clone();
        // Detaching the builder cancels GPUI's pending and visible tooltip state on leave.
        // Its default tooltip hit test otherwise uses the stale last in-window position.
        let tooltips_enabled = window.is_window_hovered() && self.bar.visible;
        let sources = &self.sources;
        let clock = (sources.clock.read(cx).state.target.as_ref())
            .map_or_else(|| "--:--".into(), |clock| clock.time.clone());
        let tooltip = |element: Stateful<Div>, tooltip: TooltipBuilder| {
            element.when(tooltips_enabled, |element| {
                element.hoverable_tooltip(tooltip)
            })
        };
        // Labels for tooltips, from each source's latest value.
        fn label<S: DataSource>(data: &Data<S>, label: impl Fn(&S::Value) -> String) -> String {
            data.state.target.as_ref().map_or_else(|| "…".into(), label)
        }
        // Coloured by usage; the disk shows free space but is coloured by used space.
        let [cpu, memory, disk] = sources.system.read(cx).state.target.as_ref().map_or_else(
            || ["--%", "--%", "--"].map(|label| (label.to_owned(), theme::SYSTEM_ACCENT)),
            |stats| {
                [
                    (format!("{}%", stats.cpu), theme::usage(stats.cpu)),
                    (format!("{}%", stats.memory), theme::usage(stats.memory)),
                    (stats.disk_free_label(), theme::usage(stats.disk)),
                ]
            },
        );
        let brightness = sources
            .brightness
            .read(cx)
            .state
            .target
            .as_ref()
            .map_or_else(
                || "--%".into(),
                |brightness| format!("{}%", brightness.percent),
            );

        let profile = self
            .module(
                Module::PowerProfile,
                self.profile_icon.clone(),
                theme::POWER_ACCENT,
            )
            .when(tooltips_enabled, |button| {
                // Keep the popup alive through clicks while its button stays hovered.
                button.hoverable_tooltip({
                    let icon = self.profile_icon.clone();
                    move |window, cx| ProfileIcon::tooltip(&icon, window, cx)
                })
            });
        let volume = self
            .module(
                Module::Volume,
                self.volume_button.clone(),
                theme::VOLUME_ACCENT,
            )
            .when(tooltips_enabled, |button| {
                button.hoverable_tooltip({
                    let volume = self.volume_button.clone();
                    move |window, cx| VolumeButton::tooltip(&volume, window, cx)
                })
            });
        let [cpu, memory, disk] = [
            (Module::Cpu, Icon::Cpu, cpu),
            (Module::Memory, Icon::Memory, memory),
            (Module::Disk, Icon::Disk, disk),
        ]
        .map(|(module, icon, (label, color))| {
            self.module(module, labelled(icon, color, label), color)
        });
        let cpu = tooltip(
            cpu,
            Box::new(text_tooltip(
                &sources.system,
                theme::SYSTEM_ACCENT,
                |data| label(data, |stats| stats.cpu_temperature_label()),
            )),
        );
        let memory = tooltip(
            memory,
            Box::new(text_tooltip(
                &sources.system,
                theme::SYSTEM_ACCENT,
                |data| label(data, |stats| stats.memory_label()),
            )),
        );
        let clock = tooltip(
            self.module(Module::Clock, clock, theme::CLOCK_ACCENT),
            Box::new(text_tooltip(&sources.clock, theme::CLOCK_ACCENT, |data| {
                label(data, |clock| clock.date.clone())
            })),
        );
        let brightness = tooltip(
            self.module(
                Module::Brightness,
                labelled(Icon::Sun, theme::BRIGHTNESS_ACCENT, brightness),
                theme::BRIGHTNESS_ACCENT,
            ),
            Box::new(text_tooltip(
                &sources.brightness,
                theme::BRIGHTNESS_ACCENT,
                |data| label(data, |brightness| brightness.display.clone()),
            )),
        );
        let battery = tooltip(
            self.module(Module::Battery, self.battery.clone(), theme::BATTERY_ACCENT),
            Box::new(text_tooltip(
                &sources.battery,
                theme::BATTERY_ACCENT,
                |data| label(data, |battery| battery.time_label()),
            )),
        );

        let profile = Self::clickable(profile, Module::PowerProfile, cx);
        let volume = Self::clickable(volume, Module::Volume, cx);
        let volume = Self::adjustable(volume, Module::Volume, cx);
        // Muted while off, so it reads as a toggle.
        let caffeine_color = if sources.caffeine.read(cx).active {
            theme::CAFFEINE_ACCENT
        } else {
            theme::MUTED
        };
        let caffeine = self.module(
            Module::Caffeine,
            static_icon(Icon::Coffee, caffeine_color),
            caffeine_color,
        );
        let caffeine = tooltip(
            caffeine,
            Box::new(text_tooltip(
                &sources.caffeine,
                theme::CAFFEINE_ACCENT,
                |caffeine| {
                    if caffeine.active {
                        "Caffeine enabled".into()
                    } else {
                        "Caffeine disabled".into()
                    }
                },
            )),
        );
        let caffeine = Self::clickable(caffeine, Module::Caffeine, cx);
        let brightness = Self::clickable(brightness, Module::Brightness, cx);
        let brightness = Self::adjustable(brightness, Module::Brightness, cx);

        let left = self.section([profile, battery, cpu, memory, disk]);
        let center = self.section([clock]);
        let notifications = self.notifications_island(cx);
        let right = self.section([caffeine, brightness, volume, notifications]);
        // Equal-basis sides keep the clock at the display's centre, whatever their contents.
        // Top-aligned, so the dropdown grows downwards.
        let side = || div().flex_1().flex().items_start();
        // While peeking, the row stays put and each peeked module is offset on its own.
        let offset = if self.bar.hidden() {
            0.
        } else {
            slide_offset(self.bar_progress)
        };
        let content = div()
            .absolute()
            .top(px(offset))
            .w_full()
            .h(px(HEIGHT))
            .flex()
            .items_start()
            .pt(px(PAD_Y))
            .gap_2()
            .px(px(EDGE_MARGIN))
            .text_color(theme::FOREGROUND)
            .font_family("Josefin Sans")
            // Rem-based, so `scaled` can scale it.
            .text_size(rems(1.))
            .child(side().child(left))
            .child(center)
            .child(side().justify_end().child(right));
        self.liquid.borrow_mut().clear();
        let liquid = self.liquid.clone();
        div()
            .size_full()
            .relative()
            .overflow_hidden()
            // Painted first, so it sits behind the content whose bounds it follows.
            .child(
                canvas(
                    |_, _, _| {},
                    move |bounds, _, window, _| {
                        let mut input = Vec::with_capacity(2);
                        if input_bar {
                            input.push(Bounds::new(
                                bounds.origin,
                                gpui::size(bounds.size.width, px(HEIGHT)),
                            ));
                        }
                        if input_island && let Some(island) = island.get() {
                            input.push(island.dilate(px(BLOB_PAD_X)));
                        }
                        window.set_input_region(Some(&input));
                        let outlines: Vec<_> = (liquid.borrow().iter().copied())
                            .flat_map(|body| [blob(body), fillet(body)])
                            .flatten()
                            .collect();
                        if let Some(path) = liquid::path(&outlines) {
                            window.paint_path(path, theme::BACKGROUND);
                        }
                        if let Some(blur) = blur.borrow_mut().as_mut() {
                            blur.set_region(liquid::rows(&outlines));
                        }
                    },
                )
                .absolute()
                .inset_0(),
            )
            .child(content)
            .into_any_element()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn liquid_has_no_sharp_corners_at_any_progress() {
        let mut failures = Vec::new();
        for step in 0..=200 {
            let progress = step as f32 / 200.;
            // Below 6px tall, every curve is a pixel or two across, so even a correct
            // semicircle turns more than the threshold within the 2px window.
            if HEIGHT * progress < 6. {
                continue;
            }
            for (width, height) in [(20., HEIGHT), (400., HEIGHT), (360., 500.)] {
                let body = Body {
                    left: 100.,
                    right: 100. + width,
                    height,
                    progress,
                    fillet: false,
                };
                let Some(outline) = blob(body) else {
                    continue;
                };
                let corners = liquid::tests::sharp_corners(&outline, 2., 60.);
                if let Some(worst) = corners.iter().max_by(|a, b| a.0.total_cmp(&b.0)) {
                    failures.push(format!(
                        "{width}x{height}, progress {progress:.3}: {:.0}° at ({:.1}, {:.1})",
                        worst.0, worst.1.0, worst.1.1
                    ));
                }
            }
        }
        assert!(failures.is_empty(), "{}", failures.join("\n"));
    }
}
