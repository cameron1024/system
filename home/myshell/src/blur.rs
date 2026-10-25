//! Shaped background blur through ext-background-effect, which GPUI doesn't expose. This shares
//! GPUI's libwayland connection (as a foreign display) with a private event queue, so requests
//! are ordered before GPUI's next commit of the surface, which applies them.

use raw_window_handle::HasDisplayHandle;
use raw_window_handle::HasWindowHandle;
use raw_window_handle::RawDisplayHandle;
use raw_window_handle::RawWindowHandle;
use wayland_backend::client::Backend;
use wayland_backend::client::ObjectId;
use wayland_client::Connection;
use wayland_client::Dispatch;
use wayland_client::EventQueue;
use wayland_client::Proxy;
use wayland_client::QueueHandle;
use wayland_client::delegate_noop;
use wayland_client::globals::GlobalListContents;
use wayland_client::globals::registry_queue_init;
use wayland_client::protocol::wl_compositor::WlCompositor;
use wayland_client::protocol::wl_region::WlRegion;
use wayland_client::protocol::wl_registry;
use wayland_client::protocol::wl_surface::WlSurface;
use wayland_protocols::ext::background_effect::v1::client::ext_background_effect_manager_v1::ExtBackgroundEffectManagerV1;
use wayland_protocols::ext::background_effect::v1::client::ext_background_effect_surface_v1::ExtBackgroundEffectSurfaceV1;

/// Surface-local logical (x, y, width, height).
pub type Rect = (i32, i32, i32, i32);

struct State;

impl Dispatch<wl_registry::WlRegistry, GlobalListContents> for State {
    fn event(
        _: &mut Self,
        _: &wl_registry::WlRegistry,
        _: wl_registry::Event,
        _: &GlobalListContents,
        _: &Connection,
        _: &QueueHandle<Self>,
    ) {
    }
}

delegate_noop!(State: ignore WlCompositor);
delegate_noop!(State: ignore WlRegion);
delegate_noop!(State: ignore ExtBackgroundEffectManagerV1);
delegate_noop!(State: ignore ExtBackgroundEffectSurfaceV1);

pub struct Blur {
    connection: Connection,
    queue: EventQueue<State>,
    compositor: WlCompositor,
    effect: ExtBackgroundEffectSurfaceV1,
    region: Vec<Rect>,
}

impl Blur {
    /// None if the compositor doesn't support background effects.
    pub fn new(window: &gpui::Window) -> Option<Self> {
        let RawDisplayHandle::Wayland(display) = window.display_handle().ok()?.as_raw() else {
            return None;
        };
        // Window has an inherent `window_handle` (GPUI's own handle type), so name the trait.
        let handle = HasWindowHandle::window_handle(window).ok()?;
        let RawWindowHandle::Wayland(surface) = handle.as_raw() else {
            return None;
        };
        // SAFETY: both are GPUI's live display and surface. The display outlives every window,
        // and this object is owned by the surface's window, so it can't outlive the surface.
        let connection = Connection::from_backend(unsafe {
            Backend::from_foreign_display(display.display.as_ptr().cast())
        });
        let surface =
            unsafe { ObjectId::from_ptr(WlSurface::interface(), surface.surface.as_ptr().cast()) }
                .ok()?;
        let surface = WlSurface::from_id(&connection, surface).ok()?;
        let (globals, queue) = registry_queue_init::<State>(&connection).ok()?;
        let qh = queue.handle();
        let compositor: WlCompositor = globals.bind(&qh, 1..=1, ()).ok()?;
        let manager: ExtBackgroundEffectManagerV1 = globals.bind(&qh, 1..=1, ()).ok()?;
        let effect = manager.get_background_effect(&surface, &qh, ());
        Some(Self {
            connection,
            queue,
            compositor,
            effect,
            region: Vec::new(),
        })
    }

    /// Takes effect with GPUI's next commit, so call it while building the frame.
    pub fn set_region(&mut self, region: Vec<Rect>) {
        if region == self.region {
            return;
        }
        let qh = self.queue.handle();
        let wl_region = self.compositor.create_region(&qh, ());
        for &(x, y, width, height) in &region {
            wl_region.add(x, y, width, height);
        }
        self.effect.set_blur_region(Some(&wl_region));
        wl_region.destroy();
        self.region = region;
        // Our queue only receives the manager's capabilities and object deletions.
        let _ = self.queue.dispatch_pending(&mut State);
        let _ = self.connection.flush();
    }
}
