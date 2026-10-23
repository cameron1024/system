use gpui::AnyView;
use gpui::App;
use gpui::AppContext;
use gpui::Context;
use gpui::Entity;
use gpui::IntoElement;
use gpui::Render;
use gpui::Window;

use crate::animated_icon::AnimatedIcon;
use crate::animated_icon::Icon;
use crate::data_source::Data;
use crate::data_source::power_profile::PowerProfile;
use crate::data_source::power_profile::Profile;
use crate::theme;
use crate::tooltip::below_bar;
use crate::tooltip::tooltip;

fn icon(profile: Option<&Profile>) -> Icon {
    match profile {
        Some(Profile::Performance) => Icon::Rocket,
        Some(Profile::PowerSaver) => Icon::Leaf,
        Some(Profile::Balanced) => Icon::Scales,
        Some(Profile::Unknown(_)) | None => Icon::Unknown,
    }
}

pub struct ProfileIcon {
    icon: Entity<AnimatedIcon>,
    source: Entity<Data<PowerProfile>>,
}

impl ProfileIcon {
    pub fn tooltip(icon: &Entity<Self>, window: &mut Window, cx: &mut App) -> AnyView {
        let source = icon.read(cx).source.clone();
        let content = cx.new(|cx| {
            cx.observe(&source, |_, _, cx| cx.notify()).detach();
            ProfileTooltip { source }
        });
        below_bar(content, window, cx)
    }

    pub fn new(source: Entity<Data<PowerProfile>>, cx: &mut Context<Self>) -> Self {
        let initial = icon(source.read(cx).state.target.as_ref());
        let animated = cx.new(|_| AnimatedIcon::new(initial, theme::POWER_ACCENT));
        cx.observe(&source, |this, source, cx| {
            let target = icon(source.read(cx).state.target.as_ref());
            this.icon
                .update(cx, |icon, cx| icon.set(target, theme::POWER_ACCENT, cx));
        })
        .detach();
        Self {
            icon: animated,
            source,
        }
    }
}

impl Render for ProfileIcon {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        self.icon.clone()
    }
}

struct ProfileTooltip {
    source: Entity<Data<PowerProfile>>,
}

impl Render for ProfileTooltip {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let data = self.source.read(cx);
        let label = match data.state.target.as_ref() {
            Some(Profile::Performance) => "Performance",
            Some(Profile::PowerSaver) => "Power saver",
            Some(Profile::Balanced) => "Balanced",
            Some(Profile::Unknown(name)) => name.as_str(),
            None if data.error.is_some() => "Power unavailable",
            None => "Power …",
        };
        tooltip(label.to_owned(), theme::POWER_ACCENT)
    }
}
