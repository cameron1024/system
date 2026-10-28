use std::cell::Cell;
use std::cell::RefCell;
use std::ops::Range;
use std::path::PathBuf;
use std::rc::Rc;
use std::time::Duration;
use std::time::Instant;

use futures::channel::mpsc;

use gpui::Bounds;

use gpui::Context;
use gpui::Div;
use gpui::ElementId;
use gpui::Entity;
use gpui::FocusHandle;
use gpui::IntoElement;
use gpui::MouseButton;
use gpui::MouseDownEvent;
use gpui::Pixels;
use gpui::SharedString;
use gpui::Task;
use gpui::WindowHandle;

use gpui::AnyElement;
use gpui::App;
use gpui::DispatchPhase;
use gpui::MouseMoveEvent;
use gpui::ObjectFit;
use gpui::Render;
use gpui::Rgba;
use gpui::ScrollDelta;
use gpui::ScrollWheelEvent;
use gpui::Stateful;
use gpui::TouchPhase;
use gpui::UniformListScrollHandle;
use gpui::Window;
use gpui::canvas;
use gpui::div;
use gpui::img;
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
use crate::data_source::tray::TrayItem;
use crate::liquid;
use crate::notifications::Activation;
use crate::notifications::Notification;
use crate::outside_click;
use crate::outside_click::OutsideClick;
use crate::profile_icon::ProfileIcon;
use crate::reveal::Reveal;
use crate::reveal::Tween;
use crate::scaled::scaled;
use crate::shell::Sources;
use crate::theme;
use crate::tooltip::static_tooltip;
use crate::tooltip::text_tooltip;
use crate::tray;

type TooltipBuilder = Box<dyn Fn(&mut Window, &mut gpui::App) -> gpui::AnyView>;
use crate::volume_button::VolumeButton;

mod launcher_island;

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

const TRAY_MENU_WIDTH: f32 = 320.;

/// A tray menu's height below the module, at rest.
fn tray_body(menu: &[crate::data_source::tray::MenuEntry]) -> f32 {
    LIST_PAD / 2. + tray::menu_height(menu) + LIST_PAD_BOTTOM
}

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
    /// Joins bar-height bodies on its left and right with concave fillets.
    fillets: [bool; 2],
    /// Those bodies' progress, which may differ (e.g. an open dropdown stays while the bar hides).
    neighbours: f32,
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

/// For a body taller than the bar, joined to the bar-height bodies beside it.
fn fillets(body: Body) -> impl Iterator<Item = liquid::Outline> {
    let progress = body.progress.clamp(0., 1.);
    // With no neighbour left, this is exactly the blob's own flare, so it can stay.
    let neighbour_bottom = HEIGHT * body.neighbours.clamp(0., 1.);
    let radius = liquid::FLARE.min((body.height * progress - neighbour_bottom) / 2.);
    // Matches blob's sides.
    let centre = (body.left + body.right) / 2.;
    let half = ((body.right - body.left) / 2. + BLOB_PAD_X)
        * (START_WIDTH + (1. - START_WIDTH) * progress);
    [(centre - half, true), (centre + half, false)]
        .into_iter()
        .zip(body.fillets)
        .filter(move |(_, joined)| *joined && radius >= 0.5)
        .map(move |((x, left), _)| liquid::fillet(x, neighbour_bottom, radius, left))
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
    /// A notification being swiped horizontally, and how far.
    swiping: Option<(i32, f32)>,
    /// The key of the item whose tray menu is shown (including while closing).
    tray_menu: Option<String>,
    tray_reveal: Reveal,
    tray_progress: f32,
    /// The open tray menu's bounds, recorded during prepaint for the input region.
    tray_island: Rc<Cell<Option<Bounds<Pixels>>>>,
    /// Watches for clicks outside the shell while a group is open.
    outside_click: Option<WindowHandle<OutsideClick>>,
    launcher: Reveal,
    launcher_progress: f32,
    /// It was opened with the bar hidden, so it slides down whole rather than growing.
    launcher_slides: bool,
    /// The launcher's results' height, in rows.
    launcher_rows: Tween,
    launcher_focus: FocusHandle,
    /// How the window takes the keyboard: for the launcher, and while handing over from it.
    launcher_keyboard: gpui::layer_shell::KeyboardInteractivity,
    /// After a swipe dismisses a notification, the time of the latest scroll event. Swipes are
    /// ignored until scrolling stops, so one long scroll can't dismiss the rows sliding up.
    swipe_blocked: Option<Instant>,
    list_scroll: UniformListScrollHandle,
    /// Opened with the bell or a shortcut, rather than by hovering the toast.
    pinned: bool,
    hover_open: bool,
    /// The right section's bounds, recorded during prepaint: with the island, the contiguous
    /// liquid that keeps a hovered-open dropdown open.
    section: Rc<Cell<Option<Bounds<Pixels>>>>,
    /// Where hovering opens the dropdown around the toasts, if they're drawn.
    toast_area: Option<Bounds<Pixels>>,
    /// Recent arrivals, each floating where it would be in the dropdown.
    toasts: Vec<Toast>,
    /// Hides the toasts. Restarted by arrivals and by the pointer leaving; absent while it's over
    /// the shell.
    toast_timer: Option<Task<()>>,
    /// The pointer is over the shell's UI (its input region).
    hovered: bool,
    /// Eases the list's scroll offset, e.g. back to the top as a hovered-open dropdown closes.
    scroll_tween: Option<Tween>,
    /// The read notifications were just shown, so the list scrolls to the first (once loaded).
    scroll_to_read: bool,
    /// The toasts' background, in rows.
    toast_rows: Tween,
    /// The dropdown list's height, in rows.
    list_rows: Tween,
}

/// A notification shown below the bar after arriving.
struct Toast {
    notification: Notification,
    reveal: Reveal,
    /// Its row in the dropdown, which it follows (e.g. sliding up when one above leaves).
    row: Tween,
}

pub enum ModuleAction {
    Click(Module),
    Adjust(Module, i32),
    Notifications(NotificationAction),
    /// On the bar in this window.
    ToggleLauncher(gpui::AnyWindowHandle),
}

#[derive(Clone, Copy)]
pub enum NotificationAction {
    MarkAllRead,
    ToggleShowRead,
    LoadMore,
    CloseDropdown,
}

impl Bar {
    pub fn set_visible(&mut self, visible: bool, window: &mut Window, cx: &mut Context<Self>) {
        // The full bar includes every module, so it replaces any peeks.
        self.peeks.clear();
        if !visible {
            self.close_tray_menu(cx);
        }
        let (reduce_motion, now) = (cx.reduce_motion(), Instant::now());
        if self.bar.set(visible, reduce_motion, now) {
            self.scroll_remainder = 0.;
            // Until the next frame, neither stale nor newly revealed content accepts clicks.
            window.set_input_region(Some(&[]));
        }
        cx.notify();
    }

    pub fn set_dropdown(&mut self, open: bool, cx: &mut Context<Self>) {
        self.pinned = open;
        if !open {
            self.hover_open = false;
        }
        self.sync_dropdown(cx);
    }

    /// Only one group (the notifications dropdown or a tray menu) is open at once.
    fn sync_dropdown(&mut self, cx: &mut Context<Self>) {
        let open = self.pinned || self.hover_open;
        self.dropdown.set(open, cx.reduce_motion(), Instant::now());
        if open {
            self.set_launcher(false, cx);
            self.close_tray_menu(cx);
        }
        self.sync_outside_click(cx);
        cx.notify();
    }

    /// While a group is open, clicks outside the shell close it. Call while handling the press
    /// that may open one (see `outside_click`); it stops watching if none opens.
    fn watch_outside_clicks(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.outside_click.is_some() {
            return;
        }
        let Some((handle, root)) = outside_click::open(window, cx) else {
            return;
        };

        // Released when the compositor dismisses it, or when it's no longer needed.
        cx.observe_release(&root, |this, _, cx| {
            this.outside_click = None;
            // e.g. to release the keyboard.
            cx.notify();
            this.close_tray_menu(cx);
            if this.pinned {
                let action = ModuleAction::Notifications(NotificationAction::CloseDropdown);
                let _ = this.actions.unbounded_send(action);
            }
        })
        .detach();
        self.outside_click = Some(handle);
    }

    fn sync_outside_click(&mut self, cx: &mut Context<Self>) {
        if self.pinned || self.tray_reveal.visible {
            return;
        }
        if let Some(handle) = self.outside_click.take() {
            cx.defer(move |cx| {
                let _ = handle.update(cx, |_, window, _| window.remove_window());
            });
        }
    }

    /// Shows the newest notification below the bar for a few seconds, below any still shown.
    pub fn show_toast(&mut self, cx: &mut Context<Self>) {
        let notifications = self.sources.notifications.read(cx);
        let Some(newest) = notifications
            .visible()
            .first()
            .filter(|entry| !entry.is_read())
            .cloned()
        else {
            return;
        };
        // Updates don't extend the toasts' time.
        if (self.toasts.iter()).any(|toast| toast.notification.id == newest.id) {
            return;
        }
        let now = Instant::now();
        let mut reveal = Reveal::new(false, now);
        reveal.set(true, cx.reduce_motion(), now);
        self.toasts.push(Toast {
            notification: newest,
            reveal,
            row: Tween::new(0., now),
        });
        self.restart_toast_timer(cx);
        cx.notify();
    }

    /// After `TOAST_DURATION`, the toasts leave one by one, oldest first. Paused while hovered.
    fn restart_toast_timer(&mut self, cx: &mut Context<Self>) {
        self.toast_timer = (!self.hovered).then(|| {
            cx.spawn(async move |this, cx| {
                async_io::Timer::after(TOAST_DURATION).await;
                // Ids increase with arrival.
                while let Ok(true) = this.update(cx, |this, cx| {
                    let oldest = (this.toasts.iter())
                        .filter(|toast| toast.reveal.visible)
                        .map(|toast| toast.notification.id)
                        .min();
                    oldest.inspect(|&id| this.hide_toast(id, cx)).is_some()
                }) {
                    async_io::Timer::after(TOAST_STAGGER).await;
                }
            })
        });
    }

    fn hide_toast(&mut self, id: i32, cx: &mut Context<Self>) {
        let reduce_motion = cx.reduce_motion();
        if let Some(toast) = (self.toasts.iter_mut()).find(|toast| toast.notification.id == id) {
            toast.reveal.set(false, reduce_motion, Instant::now());
            cx.notify();
        }
    }

    fn hide_toasts(&mut self, cx: &mut Context<Self>) {
        let ids: Vec<i32> = (self.toasts.iter())
            .map(|toast| toast.notification.id)
            .collect();
        for id in ids {
            self.hide_toast(id, cx);
        }
    }

    /// Hovering a toast expands the dropdown around it, until the pointer leaves the whole
    /// contiguous liquid (the toasts, the dropdown, and the right section). Hit-testing the area
    /// directly means gaps between elements (e.g. reaching for the controls) never count as
    /// leaving.
    fn pointer_moved(&mut self, position: gpui::Point<Pixels>, cx: &mut Context<Self>) {
        if !self.hovered {
            self.hovered = true;
            self.toast_timer = None;
        }
        let pad = px(BLOB_PAD_X);
        let over_toasts = (self.toast_area).is_some_and(|area| area.contains(&position));
        let over_island =
            (self.island.get()).is_some_and(|island| island.dilate(pad).contains(&position));
        let over_section = !self.bar.hidden()
            && (self.section.get()).is_some_and(|section| {
                // Only the bar-height strip: below the modules is empty, not liquid.
                let strip = Bounds::new(
                    gpui::point(section.left() - pad, px(0.)),
                    gpui::size(section.size.width + pad * 2., px(HEIGHT)),
                );
                strip.contains(&position)
            });
        let toasting = self.toasts.iter().any(|toast| toast.reveal.visible);
        // The launcher takes input everywhere while open; moving over the toasts mustn't close it.
        let launching = self.launcher.visible;
        if over_toasts && toasting && !self.hover_open && !self.pinned && !launching {
            self.hover_open = true;
            self.sync_dropdown(cx);
        } else if self.hover_open && !over_toasts && !over_island && !over_section {
            self.unhover(cx);
        }
    }

    /// Closes the hovered-open dropdown, scrolling its list back to the top (where the toasts
    /// are) as it goes.
    fn unhover(&mut self, cx: &mut Context<Self>) {
        if !self.hover_open {
            return;
        }
        self.hover_open = false;
        self.sync_dropdown(cx);
        self.scroll_to_read = false;
        self.scroll_list(0.);
    }

    /// Eases the list's scroll offset to `to` (negative, scrolling down).
    fn scroll_list(&mut self, to: f32) {
        let offset = f32::from(self.list_scroll.0.borrow().base_handle.offset().y);
        if (offset - to).abs() >= 0.5 {
            let now = Instant::now();
            let mut tween = Tween::new(offset, now).with_duration(SCROLL_EASE);
            tween.set(to, now);
            self.scroll_tween = Some(tween);
        }
    }

    /// Whether toasts are drawn: until the dropdown has fully opened beneath them.
    fn toasts_shown(&self) -> bool {
        !self.toasts.is_empty() && self.dropdown_progress < 1.
    }

    /// Whether a toast draws this notification's card, in place of the dropdown's.
    fn toast_covers(&self, id: i32) -> bool {
        self.toasts_shown()
            && (self.toasts.iter()).any(|toast| toast.notification.id == id && toast.reveal.visible)
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
        !self.bar.hidden()
            || !self.peeks.is_empty()
            || !self.dropdown.hidden()
            || !self.launcher.hidden()
            || !self.toasts.is_empty()
    }

    pub fn new(
        sources: Sources,
        actions: mpsc::UnboundedSender<ModuleAction>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Self {
        // e.g. clicking another window while the launcher has the keyboard.
        cx.observe_window_activation(window, |this, window, cx| {
            if !window.is_window_active() {
                this.set_launcher(false, cx);
            }
        })
        .detach();
        redraw_on(&sources.launcher, cx);
        // Modules without their own view are rendered inline from these sources.
        redraw_on(&sources.clock, cx);
        redraw_on(&sources.system, cx); // CPU, memory and disk
        redraw_on(&sources.brightness, cx);
        redraw_on(&sources.caffeine, cx);
        redraw_on(&sources.notifications, cx);
        redraw_on(&sources.tray, cx);
        // The battery indicator redraws itself; the bar only needs to when it appears or goes.
        let mut battery_available = sources.battery.read(cx).available;
        cx.observe(&sources.battery, move |_, battery, cx| {
            let available = battery.read(cx).available;
            if std::mem::replace(&mut battery_available, available) != available {
                cx.notify();
            }
        })
        .detach();
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
            swiping: None,
            swipe_blocked: None,
            tray_menu: None,
            tray_reveal: Reveal::new(false, Instant::now()),
            tray_progress: 0.,
            tray_island: Rc::default(),
            outside_click: None,
            launcher: Reveal::new(false, Instant::now()),
            launcher_progress: 0.,
            launcher_slides: false,
            launcher_rows: Tween::new(1., Instant::now()),
            launcher_focus: cx.focus_handle(),
            launcher_keyboard: gpui::layer_shell::KeyboardInteractivity::None,
            list_scroll: UniformListScrollHandle::new(),
            pinned: false,
            hover_open: false,
            section: Rc::default(),
            toast_area: None,
            toasts: Vec::new(),
            toast_timer: None,
            hovered: false,
            scroll_tween: None,
            scroll_to_read: false,
            toast_rows: Tween::new(0., Instant::now()),
            list_rows: Tween::new(0., Instant::now()),
        }
    }

    fn module(&self, module: Module, content: impl IntoElement, accent: Rgba) -> Stateful<Div> {
        let peeked = (self.peek_progress.iter())
            .find(|(peeked, _)| *peeked == module)
            .map(|&(_, progress)| progress);
        self.revealed(module.name(), peeked, content, accent)
    }

    /// How far the content row is slid up: with the bar. While peeking, it stays put and each
    /// peeked module (or open group) is offset on its own, countering this.
    fn row_offset(&self) -> f32 {
        if self.bar.hidden() {
            0.
        } else {
            slide_offset(self.bar_progress)
        }
    }

    /// Content fades and scales in as it's revealed. While peeking (`peeked` is its progress),
    /// other modules keep their layout space so the peeked one doesn't move.
    fn revealed(
        &self,
        id: impl Into<ElementId>,
        peeked: Option<f32>,
        content: impl IntoElement,
        accent: Rgba,
    ) -> Stateful<Div> {
        let progress = match peeked {
            _ if !self.bar.hidden() => self.bar_progress,
            Some(progress) => progress,
            None => 0.,
        };
        let scale = START_SCALE + (1. - START_SCALE) * progress;
        let element = bar_module(id, scaled(scale, content), accent)
            .flex_shrink_0()
            .opacity(progress);
        match peeked {
            _ if !self.bar.hidden() => element,
            // Offset visually only, so neighbours never move.
            Some(progress) => element
                .relative()
                .top(px(slide_offset(progress)))
                .child(self.liquid_anchor(progress, None, [false; 2])),
            None => element.invisible(),
        }
    }

    /// A tray item, as a module. Clicking opens its menu, which it grows into like the
    /// notifications module: it widens to show its title, and the menu drops below. Right-clicking
    /// activates it (e.g. raising a window). `first` in its section, nothing is joined on its left.
    fn tray_module(
        &self,
        item: TrayItem,
        first: bool,
        tooltips_enabled: bool,
        cx: &mut Context<Self>,
    ) -> Stateful<Div> {
        let accent = if item.attention {
            theme::WARNING
        } else if tray::unread(&item).is_some() {
            // Like the notifications module with unread notifications.
            theme::NOTIFICATION_ACCENT
        } else {
            theme::TRAY_ACCENT
        };
        let open = self.tray_menu.as_deref() == Some(&item.key);
        let progress = if open { self.tray_progress } else { 0. };
        let title: SharedString = item.title.clone().into();
        let (toggled, activated) = (item.clone(), item.clone());
        let module = self
            .revealed(
                ElementId::Name(item.key.clone().into()),
                None,
                tray::content(&item, accent),
                accent,
            )
            .when(open && self.tray_reveal.visible, |module| {
                module.bg(theme::SELECTED)
            })
            .when(tooltips_enabled && !open, |module| {
                module.hoverable_tooltip(static_tooltip(title.clone(), accent))
            })
            .cursor_pointer()
            .on_mouse_down(
                MouseButton::Left,
                cx.listener(|this, _, window, cx| this.watch_outside_clicks(window, cx)),
            )
            .on_click(cx.listener(move |this, _, _, cx| this.toggle_tray_menu(&toggled, cx)))
            .on_mouse_down(
                MouseButton::Right,
                cx.listener(move |this, _, _, cx| {
                    this.close_tray_menu(cx);
                    if !activated.activates {
                        return;
                    }
                    let item = activated.clone();
                    cx.background_executor()
                        .spawn(async move {
                            if let Err(error) = item.activate().await {
                                eprintln!("tray item {}: {error}", item.key);
                            }
                        })
                        .detach();
                }),
            );
        // Its own presses (opening it, or choosing an entry) mustn't close it first.
        let island = div()
            .id(ElementId::Name(format!("{}-island", item.key).into()))
            .on_mouse_down(MouseButton::Left, |_, _, cx| cx.stop_propagation())
            .on_mouse_down(MouseButton::Right, |_, _, cx| cx.stop_propagation());
        if progress == 0. {
            return island.child(module);
        }
        // The title fills the space left of the module, clipped to it as the header widens. With
        // no width of its own, it never affects the island's.
        let header = div()
            .flex()
            .min_w(px(TRAY_MENU_WIDTH * progress))
            .child(
                // Padding goes inside: even at zero width, it would take space.
                div()
                    .w_0()
                    .flex_grow(1.)
                    .h(px(crate::bar_module::HEIGHT))
                    .overflow_hidden()
                    .when(self.tray_reveal.visible, |slot| {
                        slot.child(
                            div()
                                .size_full()
                                .pl(px(LIST_PAD - 2.))
                                .pr_1()
                                .flex()
                                .items_center()
                                .whitespace_nowrap()
                                .text_color(theme::FOREGROUND)
                                .opacity(progress)
                                // Clipped while opening; truncated if it's too long once open.
                                .child(
                                    div()
                                        .when(progress >= 1., |title| title.truncate())
                                        .child(title),
                                ),
                        )
                    }),
            )
            .child(module);
        let this = cx.entity().downgrade();
        let chosen = item.clone();
        let on_click: tray::OnClick = Rc::new(move |id, _, cx| {
            let item = chosen.clone();
            cx.background_executor()
                .spawn(async move {
                    if let Err(error) = item.menu_clicked(id).await {
                        eprintln!("tray menu {}: {error}", item.key);
                    }
                })
                .detach();
            let _ = this.update(cx, |bar, cx| bar.close_tray_menu(cx));
        });
        let bounds = self.tray_island.clone();
        island
            // Room between the title and the module before. Nothing after it moves, so neither
            // does the item's own module.
            .ml(px(LIST_PAD * progress))
            .flex()
            .flex_col()
            .items_end()
            .overflow_hidden()
            .h(px(
                crate::bar_module::HEIGHT + tray_body(&item.menu) * progress
            ))
            .child(header)
            .child(
                // Clipped to the animated width; the menu itself stays full width.
                div()
                    .w(px(TRAY_MENU_WIDTH * progress))
                    .flex()
                    .justify_end()
                    .overflow_hidden()
                    .child(
                        div()
                            .flex_shrink_0()
                            .w(px(TRAY_MENU_WIDTH))
                            .flex()
                            .flex_col()
                            .px(px(LIST_PAD / 2.))
                            .pt(px(LIST_PAD / 2.))
                            .opacity(progress)
                            .children(tray::rows(&item.menu, 0, &on_click)),
                    ),
            )
            .child(self.liquid_anchor(self.bar_progress, None, [!first, true]))
            .child(
                canvas(
                    move |bounds_, _, _| bounds.set(Some(bounds_)),
                    |_, _, _, _| {},
                )
                .absolute()
                .inset_0(),
            )
    }

    fn toggle_tray_menu(&mut self, item: &TrayItem, cx: &mut Context<Self>) {
        let (reduce_motion, now) = (cx.reduce_motion(), Instant::now());
        if self.tray_menu.as_deref() == Some(&item.key) {
            let visible = !self.tray_reveal.visible;
            self.tray_reveal.set(visible, reduce_motion, now);
        } else {
            // Another item's menu goes at once.
            self.tray_menu = Some(item.key.clone());
            self.tray_reveal = Reveal::new(false, now);
            self.tray_reveal.set(true, reduce_motion, now);
        }
        if self.tray_reveal.visible {
            self.set_launcher(false, cx);
        }
        if self.tray_reveal.visible && self.pinned {
            let action = ModuleAction::Notifications(NotificationAction::CloseDropdown);
            let _ = self.actions.unbounded_send(action);
        }
        self.sync_outside_click(cx);
        if self.tray_reveal.visible {
            let item = item.clone();
            cx.background_executor()
                .spawn(async move {
                    if let Err(error) = item.menu_opened().await {
                        eprintln!("tray menu {}: {error}", item.key);
                    }
                })
                .detach();
        }
        cx.notify();
    }

    fn close_tray_menu(&mut self, cx: &mut Context<Self>) {
        if self
            .tray_reveal
            .set(false, cx.reduce_motion(), Instant::now())
        {
            self.sync_outside_click(cx);
            cx.notify();
        }
    }

    /// A group of modules (skipping any that are None) with separators between them, sharing one
    /// body of liquid unless modules are peeking.
    fn section(&self, modules: impl IntoIterator<Item = Option<Stateful<Div>>>) -> Div {
        let peeking = self.bar.hidden();
        // Top-aligned, so a dropdown in the section grows downwards without moving the rest.
        let mut section = div()
            .flex()
            .items_start()
            .gap_1()
            .when(!peeking, |section| {
                // Always bar-height: a dropdown's taller body joins it with a fillet.
                section.child(self.liquid_anchor(self.bar_progress, Some(HEIGHT), [false; 2]))
            });
        for (index, module) in modules.into_iter().flatten().enumerate() {
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
    /// `fillets`, its left and right sides join bar-height bodies beside them smoothly.
    fn liquid_anchor(
        &self,
        progress: f32,
        height: Option<f32>,
        fillets: [bool; 2],
    ) -> impl IntoElement {
        let liquid = self.liquid.clone();
        // Fillets join the section's body, which follows the bar.
        let neighbours = self.bar_progress;
        canvas(
            move |bounds, _, _| {
                liquid.borrow_mut().push(Body {
                    left: f32::from(bounds.left()),
                    right: f32::from(bounds.right()),
                    height: height.unwrap_or(f32::from(bounds.size.height) + 2. * PAD_Y),
                    progress,
                    fillets,
                    neighbours,
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
        // With the bar hidden, the bell shows while peeked, while its dropdown is open, and for
        // exactly as long as any toast (so they arrive and leave together).
        let toasts = (self.toasts.iter())
            .map(|toast| toast.reveal.progress(Instant::now()))
            .fold(0., f32::max);
        // An open dropdown holds it in place while the bar shows or hides around it.
        let hold = self.dropdown_progress.max(toasts);
        let progress = if self.bar.hidden() {
            peek.unwrap_or(0.).max(hold)
        } else {
            self.bar_progress.max(hold)
        };
        let shown = !self.bar.hidden()
            || peek.is_some()
            || !self.dropdown.hidden()
            || !self.toasts.is_empty();
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
        let bell = Self::clickable(bell, Module::Notifications, cx).on_mouse_down(
            MouseButton::Left,
            cx.listener(|this, _, window, cx| this.watch_outside_clicks(window, cx)),
        );
        // The controls are positioned over the header, so they never affect the island's width
        // (which would jump as they appear or disappear). They go as soon as it starts closing.
        let header = div()
            .relative()
            .flex()
            .justify_end()
            .min_w(px(DROPDOWN_WIDTH * dropdown))
            .when(dropdown > 0. && self.dropdown.visible, |header| {
                header.child(
                    div()
                        .absolute()
                        .left_0()
                        .top_0()
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

        let rows = self.list_rows.value(Instant::now());
        let island = self.island.clone();
        div()
            .id("notifications-island")
            // Room between the controls and the module before them.
            .ml(px(LIST_PAD * dropdown))
            .flex()
            .flex_col()
            .items_end()
            .overflow_hidden()
            .h(px(
                crate::bar_module::HEIGHT + (TITLE_HEIGHT + list_height(rows)) * dropdown
            ))
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
                        .child(
                            div()
                                .flex_shrink_0()
                                .w(px(DROPDOWN_WIDTH))
                                .flex()
                                .flex_col()
                                .child(
                                    div()
                                        .flex_shrink_0()
                                        .h(px(TITLE_HEIGHT))
                                        .px(px(LIST_PAD + 2.))
                                        .flex()
                                        .items_end()
                                        .text_size(px(15.))
                                        .font_weight(gpui::FontWeight::MEDIUM)
                                        .text_color(theme::FOREGROUND)
                                        .child("Notifications"),
                                )
                                .child(self.notification_list(cx)),
                        ),
                )
            })
            // Offset visually only, like other peeked modules, and against the content row's.
            .relative()
            .top(px(slide_offset(progress) - self.row_offset()))
            .map(|this| {
                if shown {
                    // Joined to the right section's body, unless peeking on its own.
                    let fillet = !self.bar.hidden();
                    this.child(self.liquid_anchor(progress, None, [fillet, false]))
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
            .on_click(cx.listener(move |this, _, _, cx| match action {
                NotificationAction::MarkAllRead => this.mark_all_read(cx),
                action => {
                    if let NotificationAction::ToggleShowRead = action {
                        this.scroll_to_read = !this.sources.notifications.read(cx).show_read;
                    }
                    let _ = (this.actions).unbounded_send(ModuleAction::Notifications(action));
                }
            }))
    }

    /// Once the read notifications are shown, eases the list to the first, loading pages until
    /// it's found (or there are none).
    fn scroll_to_first_read(&mut self, cx: &mut Context<Self>) {
        let notifications = self.sources.notifications.read(cx);
        if !notifications.show_read {
            // The toggle hasn't applied yet.
            return;
        }
        let visible = notifications.visible();
        let first_read = visible.partition_point(|entry| !entry.is_read());
        if first_read < visible.len() {
            self.scroll_to_read = false;
            self.scroll_list(-(first_read as f32) * (ROW_HEIGHT + ROW_GAP));
        } else if notifications.exhausted() {
            self.scroll_to_read = false;
        } else if notifications.wants_more() {
            let action = ModuleAction::Notifications(NotificationAction::LoadMore);
            let _ = self.actions.unbounded_send(action);
        }
    }

    /// Unread notifications on screen swipe away from the top, slightly staggered. The rest just
    /// go, without moving the view.
    fn mark_all_read(&mut self, cx: &mut Context<Self>) {
        let notifications = self.sources.notifications.read(cx);
        let reappears = notifications.show_read;
        let visible = notifications.visible();
        let unread = visible.partition_point(|entry| !entry.is_read());
        let now = Instant::now();
        let slot = ROW_HEIGHT + ROW_GAP;
        let scroll = self.list_scroll.0.borrow().base_handle.clone();
        let offset = scroll.offset();
        // The visible part of the rows, below the list's top padding.
        let top = -f32::from(offset.y) - (LIST_PAD - ROW_GAP);
        let bottom = top + list_height(self.list_rows.value(now));
        let first = ((top / slot).floor().max(0.) as usize).min(unread);
        let end = ((bottom / slot).ceil().max(0.) as usize).clamp(first, unread);
        let animated: Vec<Notification> = visible[first..end].to_vec();
        // The rows above are removed, so the first animated one stays where it is.
        scroll.set_offset(gpui::point(offset.x, offset.y + px(first as f32 * slot)));
        for removal in &mut self.removals {
            removal.index = removal.index.saturating_sub(unread);
        }
        // All their gaps sit above whatever is first afterwards, in order.
        for (index, notification) in animated.into_iter().enumerate() {
            self.removals.push(Removal {
                index: 0,
                notification,
                started: now + STAGGER * index as u32,
                reappears,
                from: 0.,
                direction: 1.,
            });
        }
        self.hide_toasts(cx);
        (self.sources.notifications)
            .update(cx, |notifications, cx| notifications.mark_all_read(cx));
        cx.notify();
    }

    /// For notifications' times, in the clock's time zone: looking up the system's here, on the
    /// UI thread, could read the time zone database.
    fn zoned_now(&self, cx: &App) -> jiff::Zoned {
        let zone = (self.sources.clock.read(cx).state.target.as_ref())
            .map_or(jiff::tz::TimeZone::UTC, |clock| clock.zone.clone());
        jiff::Timestamp::now().to_zoned(zone)
    }

    /// Rows the dropdown is sized for, including gaps still collapsing after removals.
    fn list_rows_target(&self, now: Instant, cx: &App) -> f32 {
        let visible = self.sources.notifications.read(cx).visible().len() as f32;
        let collapsing: f32 = (self.removals.iter())
            .filter(|removal| !removal.reappears)
            .map(|removal| removal.gap(now) / (ROW_HEIGHT + ROW_GAP))
            .sum();
        visible + collapsing
    }

    /// The toasts: each card at exactly where the dropdown draws it, on a shared background that
    /// fades as the dropdown's liquid grows around them. Clicks work as in the dropdown.
    /// Each toast card's bounds within the toasts' area (see `toast_bounds`), and its progress.
    fn toast_cards(&self, now: Instant) -> impl Iterator<Item = (&Toast, Bounds<Pixels>, f32)> {
        self.toasts.iter().map(move |toast| {
            let progress = toast.reveal.progress(now);
            let origin = gpui::point(
                px(TOAST_PAD + TOAST_SLIDE * (1. - progress)),
                px(TOAST_PAD + toast.row.value(now) * (ROW_HEIGHT + ROW_GAP)),
            );
            let size = gpui::size(px(CARD_WIDTH), px(ROW_HEIGHT));
            (toast, Bounds::new(origin, size), progress)
        })
    }

    /// The toasts: each card at exactly where the dropdown draws it. Each is its own pane of
    /// glass (the liquid's tint, over blur) until the dropdown's liquid grows around it.
    fn toasts_element(&self, width: Pixels, now: Instant, cx: &mut Context<Self>) -> Stateful<Div> {
        let bounds = toast_bounds(width, self.toast_rows.value(now));
        let timestamp = self.zoned_now(cx);
        let glass = 1. - self.dropdown_progress;
        let cards: Vec<_> = (self.toast_cards(now).collect::<Vec<_>>().into_iter())
            .map(|(toast, card, progress)| {
                let id = toast.notification.id;
                div()
                    .id(("toast", id as usize))
                    .group("notification")
                    .absolute()
                    .left(card.origin.x)
                    .top(card.origin.y)
                    .w(card.size.width)
                    .h(card.size.height)
                    .opacity(progress)
                    .cursor_pointer()
                    .child(
                        div()
                            .absolute()
                            .inset_0()
                            .rounded(px(8.))
                            .bg(theme::BACKGROUND)
                            .opacity(glass),
                    )
                    .child(
                        notification_card(&toast.notification, &timestamp, Tick::Space)
                            .group_hover("notification", |card| card.bg(theme::MODULE_HOVER)),
                    )
                    .child(
                        div()
                            .id(("toast-mark-read", id as usize))
                            .group("notification-tick")
                            .absolute()
                            .top(px((ROW_HEIGHT - TICK) / 2.))
                            .right(px(TICK_INSET))
                            .child(tick().group_hover("notification-tick", |tick| {
                                tick.bg(theme::MODULE_HOVER)
                            }))
                            .on_click(cx.listener(move |this, _, _, cx| {
                                cx.stop_propagation();
                                this.hide_toast(id, cx);
                                this.remove(id, None, cx);
                            })),
                    )
                    .on_click(cx.listener(move |this, _, window, cx| {
                        this.remove(id, Some(window.request_activation_token()), cx)
                    }))
            })
            .collect();
        div()
            .id("toasts")
            .absolute()
            .left(bounds.origin.x)
            .top(bounds.origin.y)
            .w(bounds.size.width)
            .h(bounds.size.height)
            .children(cards)
    }

    /// Marks an unread notification read (and optionally acts on it), animating it out. The
    /// change applies before the next frame, so the next row's click targets are already where
    /// this one's were: rapid clicks never miss.
    /// With `act`, the notification is acted on (letting the sender raise its window, if given a
    /// token).
    fn remove(&mut self, id: i32, act: Option<Activation>, cx: &mut Context<Self>) {
        self.remove_from(id, act, 0., 1., cx);
    }

    /// As `remove`, with the card starting `from` pixels across and leaving in `direction`.
    fn remove_from(
        &mut self,
        id: i32,
        act: Option<Activation>,
        from: f32,
        direction: f32,
        cx: &mut Context<Self>,
    ) {
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
                from,
                direction,
            });
        }
        let acted = act.is_some();
        (self.sources.notifications).update(cx, |notifications, cx| {
            if let Some(activation) = act {
                notifications.act(id, activation, cx)
            } else {
                notifications.mark_read(id, cx)
            }
        });
        if acted {
            // Acting usually focuses the sender, so get out of the way.
            let action = ModuleAction::Notifications(NotificationAction::CloseDropdown);
            let _ = self.actions.unbounded_send(action);
            self.hover_open = false;
            self.hide_toasts(cx);
            self.sync_dropdown(cx);
        }
        cx.notify();
    }

    /// Only visible rows are rendered. Rendering a row within `LOAD_AHEAD` of the end loads
    /// the next page.
    fn notification_list(&self, cx: &mut Context<Self>) -> AnyElement {
        let now = Instant::now();
        let notifications = self.sources.notifications.read(cx);
        let visible = notifications.visible().len();
        let height = px(list_height(self.list_rows.value(now)));
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
        // Rows past the end host the ghosts of removed last rows. Ghosts stacked in one row
        // (from marking all read) keep their rows, so the list can stay scrolled to them.
        let count = (self.removals.iter())
            .map(|removal| removal.index + 1)
            .fold(visible, usize::max)
            .max(self.removals.len());
        let list = uniform_list(
            "notification-list",
            count,
            cx.processor(|this, range: Range<usize>, _, cx| {
                let now = Instant::now();
                let timestamp = this.zoned_now(cx);
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
                        this.notification_row(notification, index, separated, now, &timestamp, cx)
                    })
                    .collect::<Vec<_>>()
            }),
        )
        .track_scroll(&self.list_scroll)
        .flex_shrink_0()
        .w(px(DROPDOWN_WIDTH))
        .h(height)
        .px(px(LIST_PAD))
        .pt(px(LIST_PAD - ROW_GAP))
        .pb(px(LIST_PAD_BOTTOM));
        div()
            .relative()
            .flex_shrink_0()
            .child(list)
            .children(self.scrollbar(f32::from(height)))
            .into_any_element()
    }

    /// A thin thumb showing the list's position, if it scrolls. Scrolling re-renders the bar,
    /// so it follows (from the last layout's offsets).
    fn scrollbar(&self, height: f32) -> Option<Div> {
        let scroll = &self.list_scroll.0.borrow().base_handle;
        let max = f32::from(scroll.max_offset().y);
        if max < 1. {
            return None;
        }
        let track = height - 2. * SCROLLBAR_INSET;
        let thumb = (track * height / (height + max)).max(24.);
        let progress = (-f32::from(scroll.offset().y) / max).clamp(0., 1.);
        Some(
            div()
                .absolute()
                .right(px(SCROLLBAR_INSET))
                .top(px(SCROLLBAR_INSET + (track - thumb) * progress))
                .w(px(3.))
                .h(px(thumb))
                .rounded_full()
                .bg(theme::SCROLLBAR),
        )
    }

    /// A uniform-height slot, with click targets at its real position. Cards are drawn offset
    /// by the gaps of removals above, which close after the removed rows swipe away.
    fn notification_row(
        &self,
        notification: Option<Notification>,
        index: usize,
        separated: bool,
        now: Instant,
        timestamp: &jiff::Zoned,
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
                    .left(px(
                        removal.from + removal.direction * DROPDOWN_WIDTH * 0.4 * swipe
                    ))
                    .w(px(DROPDOWN_WIDTH - 2. * LIST_PAD))
                    .opacity((1. - swipe) * swipe_opacity(removal.from))
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
        // Follows a horizontal swipe in progress.
        let dragged = (self.swiping)
            .filter(|(swiped, _)| *swiped == id)
            .map_or(0., |(_, x)| x);
        let card = notification_card(
            &notification,
            timestamp,
            if read { Tick::None } else { Tick::Space },
        )
        .absolute()
        .top(px(ROW_GAP + offset))
        .left(px(dragged))
        .right(px(-dragged))
        .when(dragged != 0., |card| card.opacity(swipe_opacity(dragged)))
        .group_hover("notification", |card| card.bg(theme::MODULE_HOVER))
        // Read notifications are greyed out.
        .when(read, |card| card.opacity(0.55))
        // The toast draws this card, in the same place, until the dropdown has fully opened.
        .when(self.toast_covers(id), |card| card.invisible());
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
                                .left(px(dragged))
                                .when(dragged != 0., |tick| tick.opacity(swipe_opacity(dragged)))
                                .group_hover("notification-tick", |tick| {
                                    tick.bg(theme::MODULE_HOVER)
                                }),
                        )
                        .on_click(cx.listener(move |this, _, _, cx| {
                            // The tick is inside the row, which would otherwise act too.
                            cx.stop_propagation();
                            this.remove(id, None, cx);
                        })),
                )
            })
            .children(ghosts)
            .when(!read, |slot| {
                slot.on_scroll_wheel(
                    cx.listener(move |this, event, _, cx| this.swipe(id, event, cx)),
                )
            })
            .on_click(cx.listener(move |this, _, window, cx| {
                this.remove(id, Some(window.request_activation_token()), cx)
            }))
    }

    /// A horizontal scroll over an unread notification drags it; far enough when the gesture
    /// ends (or any notch of a horizontal wheel) marks it read, swiping it away that way.
    /// Vertical scrolls are left to the list.
    fn swipe(&mut self, id: i32, event: &ScrollWheelEvent, cx: &mut Context<Self>) {
        if self.swipe_blocked.is_some() {
            return;
        }
        let delta = event.delta.pixel_delta(px(ROW_HEIGHT));
        let (dx, dy) = (f32::from(delta.x), f32::from(delta.y));
        let active = self.swiping.filter(|(swiped, _)| *swiped == id);
        if let ScrollDelta::Lines(_) = event.delta {
            if dx.abs() > dy.abs() {
                cx.stop_propagation();
                self.remove_from(id, None, 0., dx.signum(), cx);
                self.swipe_blocked = Some(Instant::now());
            }
            return;
        }
        let x = match active {
            Some((_, x)) => x + dx,
            // Only a mostly-horizontal start is a swipe.
            None if dx.abs() > dy.abs() && dx != 0. => dx,
            None => return,
        };
        cx.stop_propagation();
        if event.touch_phase == TouchPhase::Ended {
            self.swiping = None;
            if x.abs() >= SWIPE_DISMISS {
                self.remove_from(id, None, x, x.signum(), cx);
                self.swipe_blocked = Some(Instant::now());
            }
        } else {
            self.swiping = Some((id, x));
        }
        cx.notify();
    }
}

const SCROLLBAR_INSET: f32 = 4.;

/// How far a notification must be swiped to be marked read.
const SWIPE_DISMISS: f32 = 80.;
/// Scrolling has stopped after this long without scroll events.
const SCROLL_QUIET: Duration = Duration::from_millis(200);

/// Swiped cards fade as they move away.
fn swipe_opacity(x: f32) -> f32 {
    (1. - x.abs() / DROPDOWN_WIDTH).clamp(0., 1.)
}

const SWIPE: Duration = Duration::from_millis(120);
/// Between consecutive rows when marking all read.
const STAGGER: Duration = Duration::from_millis(30);
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
    /// Where it starts (if it was being swiped), and which way it leaves.
    from: f32,
    direction: f32,
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
const APP_ICON: f32 = 32.;

/// The sender's icon, or the first letter of its name.
fn app_icon(notification: &Notification) -> AnyElement {
    let initial: String = (notification.app_name.chars().next())
        .map_or_else(String::new, |initial| initial.to_uppercase().collect());
    let letter = move || {
        div()
            .size(px(APP_ICON))
            .flex_shrink_0()
            .rounded_full()
            .flex()
            .items_center()
            .justify_center()
            .bg(theme::NOTIFICATION_ACCENT.opacity(0.2))
            .text_size(px(15.))
            .font_weight(gpui::FontWeight::MEDIUM)
            .text_color(theme::NOTIFICATION_ACCENT)
            .child(initial.clone())
            .into_any_element()
    };
    match &notification.icon {
        Some(path) => img(PathBuf::from(path))
            .size(px(APP_ICON))
            .flex_shrink_0()
            .object_fit(ObjectFit::Contain)
            .with_fallback(letter)
            .into_any_element(),
        None => letter(),
    }
}

fn notification_card(notification: &Notification, now: &jiff::Zoned, tick_: Tick) -> Div {
    const GAP: f32 = 10.;
    // Notification text is plain (no body-markup capability), but may span lines.
    let line = |text: &str| text.replace('\n', " ");
    let ticked = !matches!(tick_, Tick::None);
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
                // The time is right-aligned to the card's edge, above the tick.
                .when(ticked, |row| row.mr(px(-(TICK + GAP))))
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
                .font_weight(gpui::FontWeight::MEDIUM)
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
        .gap(px(GAP))
        .bg(theme::CARD)
        .child(app_icon(notification))
        .child(text)
        .map(|card| match tick_ {
            Tick::None => card,
            Tick::Space => card.child(div().flex_shrink_0().size(px(TICK))),
            Tick::Icon => card.child(tick()),
        })
}

/// e.g. "now", "5m ago", "3h ago", "Oct 22".
fn relative_time(received_at: i64, now: &jiff::Zoned) -> String {
    let Ok(received) = jiff::Timestamp::from_millisecond(received_at) else {
        return String::new();
    };
    let minutes = (now.timestamp().as_second() - received.as_second()) / 60;
    match minutes {
        ..1 => "now".into(),
        1..60 => format!("{minutes}m ago"),
        60..1440 => format!("{}h ago", minutes / 60),
        _ => received
            .to_zoned(now.time_zone().clone())
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
        // A fast exit can leave without element hover events, but the window always learns the
        // pointer left (and redraws), so a hover-opened dropdown can't get stuck open, nor the
        // toasts' timer paused.
        if self.hovered && !window.is_window_hovered() {
            self.hovered = false;
            self.unhover(cx);
            self.restart_toast_timer(cx);
        }
        if self.scroll_to_read {
            self.scroll_to_first_read(cx);
        }
        if let Some(tween) = &self.scroll_tween {
            let offset = gpui::point(px(0.), px(tween.value(now)));
            self.list_scroll.0.borrow().base_handle.set_offset(offset);
            if !tween.animating(now) {
                self.scroll_tween = None;
            }
        }
        self.dropdown.settle(now);
        self.dropdown_progress = self.dropdown.progress(now);
        self.launcher.settle(now);
        self.launcher_progress = self.launcher.progress(now);
        // The results' height eases to fit them, except while closed.
        let rows =
            (self.sources.launcher.read(cx).results().len()).clamp(1, crate::launcher::VISIBLE);
        if self.launcher.hidden() {
            self.launcher_rows.snap(rows as f32, now);
        } else {
            self.launcher_rows.set(rows as f32, now);
        }
        self.tray_reveal.settle(now);
        self.tray_progress = self.tray_reveal.progress(now);

        // The open tray menu's height, for the surface. It goes if its item does.
        let tray_height = (self.tray_menu.as_ref())
            .filter(|_| !self.tray_reveal.hidden())
            .and_then(|key| {
                let items = self.sources.tray.read(cx).state.target.as_deref()?;
                let item = items.iter().find(|item| item.key == *key)?;
                Some(HEIGHT + tray_body(&item.menu))
            });
        if tray_height.is_none() {
            self.tray_menu = None;
        }

        // Toasts follow their notification's row in the dropdown, and slide out once it's read
        // (e.g. elsewhere) or there's no room for it.
        let reduce_motion = cx.reduce_motion();
        let visible = self.sources.notifications.read(cx).visible();
        for toast in &mut self.toasts {
            toast.reveal.settle(now);
            let row = (visible.iter())
                .position(|entry| entry.id == toast.notification.id && !entry.is_read());
            match row {
                Some(row) if row < MAX_TOASTS => toast.row.set(row as f32, now),
                _ if toast.reveal.visible => {
                    toast.reveal.set(false, reduce_motion, now);
                }
                _ => {}
            }
        }
        self.toasts.retain(|toast| !toast.reveal.hidden());
        let toast_rows = (self.toasts.iter())
            .filter(|toast| toast.reveal.visible)
            .map(|toast| toast.row.value(now) + 1.)
            .fold(0., f32::max);
        if self.toasts.is_empty() {
            self.toast_rows.snap(1., now);
        } else if toast_rows > 0. {
            self.toast_rows.set(toast_rows, now);
        }
        // The dropdown's height eases to fit its rows, except while closed.
        let list_rows = self.list_rows_target(now, cx);
        if self.dropdown.hidden() {
            self.list_rows.snap(list_rows, now);
        } else {
            self.list_rows.set(list_rows, now);
        }

        // The surface grows to fit the dropdown while it's shown. Its transparent remainder
        // passes input through, and the reserved space is set separately.
        let surface_height = if !self.launcher.hidden() {
            // Covering the display, so clicks anywhere else on it close the launcher.
            (window.display(cx)).map_or(HEIGHT + MAX_LIST_HEIGHT, |display| {
                f32::from(display.bounds().size.height)
            })
        } else if !self.dropdown.hidden() {
            HEIGHT + MAX_LIST_HEIGHT
        } else if !self.toasts.is_empty() {
            TOAST_TOP + MAX_TOASTS as f32 * (ROW_HEIGHT + ROW_GAP) + 2. * TOAST_PAD
        } else {
            HEIGHT
        }
        .max(tray_height.unwrap_or(0.).ceil());

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
        self.sync_launcher_window(window, cx);
        if self.bar.animating()
            || self.dropdown.animating()
            || self.tray_reveal.animating()
            || self.launcher.animating()
            || self.launcher_rows.animating(now)
            || self.toasts.iter().any(|toast| toast.reveal.animating())
            || self.toasts.iter().any(|toast| toast.row.animating(now))
            || self.toast_rows.animating(now)
            || self.list_rows.animating(now)
            || !self.removals.is_empty()
            || self.scroll_tween.is_some()
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
        let input_tray = self.tray_reveal.visible;
        let tray_island = self.tray_island.clone();
        let input_everywhere = self.launcher.visible;
        let width = window.viewport_size().width;
        let toast = (self.toasts_shown()).then(|| self.toasts_element(width, now, cx));
        let toast_bounds = toast
            .is_some()
            .then(|| toast_bounds(width, self.toast_rows.value(now)));
        // Includes everywhere above them that the dropdown's liquid would cover (e.g. its title
        // and controls, and the modules beside the bell).
        self.toast_area = toast_bounds.map(|toasts| {
            let right = width - px(EDGE_MARGIN - BLOB_PAD_X);
            let left = right - px(DROPDOWN_WIDTH + 2. * BLOB_PAD_X);
            Bounds::from_corners(
                gpui::point(left, px(0.)),
                gpui::point(right, toasts.bottom()),
            )
        });
        let toast_area = self.toast_area;
        let this = cx.entity();
        // Blur behind each toast card. Blur can't fade, so it's only there while the card's
        // glass is mostly opaque; without the glass over it, it would look like a hole.
        let toast_blur: Vec<Bounds<Pixels>> = match toast_bounds {
            Some(area) if self.dropdown_progress < 0.5 => (self.toast_cards(now))
                .filter(|(_, _, progress)| *progress > 0.5)
                .map(|(_, card, _)| card + area.origin)
                .collect(),
            _ => Vec::new(),
        };
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

        let battery = sources.battery.read(cx).available.then_some(battery);
        let brightness = sources.brightness.read(cx).available.then_some(brightness);
        let tray: Vec<TrayItem> = (sources.tray.read(cx).state.target.clone()).unwrap_or_default();
        let tray: Vec<_> = (tray.into_iter().enumerate())
            .map(|(index, item)| self.tray_module(item, index == 0, tooltips_enabled, cx))
            .collect();
        let left = self.section([Some(profile), battery, Some(cpu), Some(memory), Some(disk)]);
        let center = self.section([Some(self.launcher_island(clock, tooltips_enabled, now, cx))]);
        let notifications = self.notifications_island(cx);
        let section = self.section.clone();
        let right = self
            .section((tray.into_iter().map(Some)).chain([
                Some(caffeine),
                brightness,
                Some(volume),
                Some(notifications),
            ]))
            .child(
                canvas(
                    move |bounds, _, _| section.set(Some(bounds)),
                    |_, _, _, _| {},
                )
                .absolute()
                .inset_0(),
            );
        // Equal-basis sides keep the clock at the display's centre, whatever their contents.
        // Top-aligned, so the dropdown grows downwards.
        let side = || div().flex_1().flex().items_start();
        let offset = self.row_offset();
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
                        let bar = this.clone();
                        window.on_mouse_event(move |event: &MouseMoveEvent, phase, _, cx| {
                            if phase == DispatchPhase::Bubble {
                                bar.update(cx, |bar, cx| bar.pointer_moved(event.position, cx));
                            }
                        });
                        // Presses elsewhere in the bar close the tray menu; the compositor
                        // closes it for presses in other apps. Tray items stop propagation.
                        let bar = this.clone();
                        window.on_mouse_event(move |_: &MouseDownEvent, phase, _, cx| {
                            if phase == DispatchPhase::Bubble {
                                bar.update(cx, |bar, cx| {
                                    bar.close_tray_menu(cx);
                                    bar.set_launcher(false, cx);
                                });
                            }
                        });
                        // Before the rows' handlers, which check it. Any scroll counts, wherever.
                        window.on_mouse_event(move |_: &ScrollWheelEvent, phase, _, cx| {
                            if phase == DispatchPhase::Capture {
                                this.update(cx, |bar, _| {
                                    let now = Instant::now();
                                    bar.swipe_blocked = (bar.swipe_blocked)
                                        .filter(|last| now - *last < SCROLL_QUIET)
                                        .map(|_| now);
                                });
                            }
                        });
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
                        if input_tray && let Some(island) = tray_island.get() {
                            input.push(island.dilate(px(BLOB_PAD_X)));
                        }
                        if input_everywhere {
                            input.push(bounds);
                        }
                        input.extend(toast_area);
                        window.set_input_region(Some(&input));
                        let outlines: Vec<_> = (liquid.borrow().iter().copied())
                            .flat_map(|body| blob(body).into_iter().chain(fillets(body)))
                            .collect();
                        if let Some(path) = liquid::path(&outlines) {
                            window.paint_path(path, theme::BACKGROUND);
                        }
                        if let Some(blur) = blur.borrow_mut().as_mut() {
                            let mut region = liquid::rows(&outlines);
                            for card in &toast_blur {
                                region.extend(rounded_rows(*card, 8.));
                            }
                            blur.set_region(region);
                        }
                    },
                )
                .absolute()
                .inset_0(),
            )
            .child(content)
            .children(toast)
            // Everything, including the toasts outside the content row, uses the bar's font.
            .font_family("Josefin Sans")
            .into_any_element()
    }
}

const TOAST_DURATION: Duration = Duration::from_secs(5);
/// For the list to ease to a position, e.g. back to the top after a hovered-open dropdown closes.
const SCROLL_EASE: Duration = Duration::from_millis(400);
/// Between each toast leaving.
const TOAST_STAGGER: Duration = Duration::from_millis(250);
/// More toasts than this are still in the dropdown, just not shown below the bar.
const MAX_TOASTS: usize = 4;
/// Liquid around the toast's card.
const TOAST_PAD: f32 = 8.;
/// It slides in from (and out to) the right by this much.
const TOAST_SLIDE: f32 = 48.;
/// Above the dropdown's list, keeping the toast clear of the bar.
const TITLE_HEIGHT: f32 = 28.;
/// The dropdown's first card: below the bell, the title, the list's padding and the row's gap.
const CARD_TOP: f32 = PAD_Y + crate::bar_module::HEIGHT + TITLE_HEIGHT + LIST_PAD;
const TOAST_TOP: f32 = CARD_TOP - TOAST_PAD;
const CARD_WIDTH: f32 = DROPDOWN_WIDTH - 2. * LIST_PAD;

/// The toasts' area: around exactly where the dropdown draws its first `rows` cards. The
/// dropdown is right-aligned at the bar's edge, so this doesn't depend on its layout.
fn toast_bounds(width: Pixels, rows: f32) -> Bounds<Pixels> {
    let card_left = f32::from(width) - EDGE_MARGIN - DROPDOWN_WIDTH + LIST_PAD;
    Bounds::new(
        gpui::point(px(card_left - TOAST_PAD), px(TOAST_TOP)),
        gpui::size(
            px(CARD_WIDTH + 2. * TOAST_PAD),
            px(rows.max(1.) * (ROW_HEIGHT + ROW_GAP) - ROW_GAP + 2. * TOAST_PAD),
        ),
    )
}

/// A rounded rectangle as 1px rows, for the blur region.
fn rounded_rows(bounds: Bounds<Pixels>, radius: f32) -> Vec<crate::blur::Rect> {
    let [x, y, width, height] = [
        bounds.origin.x,
        bounds.origin.y,
        bounds.size.width,
        bounds.size.height,
    ]
    .map(f32::from);
    (0..height.round() as i32)
        .map(|row| {
            let from_edge = (row as f32 + 0.5).min(height - row as f32 - 0.5);
            let dy = (radius - from_edge).max(0.);
            let inset = radius - (radius * radius - dy * dy).max(0.).sqrt();
            (
                (x + inset).round() as i32,
                y.round() as i32 + row,
                (width - 2. * inset).round() as i32,
                1,
            )
        })
        .collect()
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
                    fillets: [false; 2],
                    neighbours: progress,
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
