//! How tray items look: their icons (overridden for known apps, so they match the bar's own) and
//! their menus, drawn by the bar rather than the app's toolkit.

use std::rc::Rc;

use gpui::AnyElement;
use gpui::App;
use gpui::ImageSource;
use gpui::Rgba;
use gpui::Window;
use gpui::div;
use gpui::img;
use gpui::prelude::*;
use gpui::px;
use gpui::rems;
use gpui::svg;

use crate::animated_icon::Icon;
use crate::animated_icon::static_icon;
use crate::data_source::tray::EntryKind;
use crate::data_source::tray::MenuEntry;
use crate::data_source::tray::TrayIcon;
use crate::data_source::tray::TrayItem;
use crate::fade::background;
use crate::theme;

/// Matched against each item's id and title, case-insensitively.
const OVERRIDES: [(&str, Icon); 4] = [
    ("handy", Icon::Hand),
    // Solaar manages Logitech devices.
    ("solaar", Icon::Mouse),
    ("blueman", Icon::Bluetooth),
    // e.g. "Slack_status_icon_1".
    ("slack", Icon::Slack),
];

pub const ROW_HEIGHT: f32 = 28.;
const SEPARATOR_HEIGHT: f32 = 9.;
/// Per submenu level.
const INDENT: f32 = 12.;

fn is(item: &TrayItem, name: &str) -> bool {
    [&item.id, &item.title]
        .iter()
        .any(|candidate| candidate.to_lowercase().contains(name))
}

/// Unread messages, for apps that only show them in their icon's pixels (which the override
/// replaces): Some, with the count if known. Slack's tooltip is e.g. "You have 3 notifications"
/// (mentions and direct messages), or "You have unread messages" (anything else).
pub fn unread(item: &TrayItem) -> Option<Option<u32>> {
    if !is(item, "slack") {
        return None;
    }
    let tooltip = item.tooltip.to_lowercase();
    let count = (tooltip.split_whitespace()).find_map(|word| word.parse::<u32>().ok());
    match count {
        Some(count) if count > 0 => Some(Some(count)),
        _ => tooltip.contains("unread").then_some(None),
    }
}

/// Its icon, then its unread count if any, like the notifications module's.
pub fn content(item: &TrayItem, color: Rgba) -> AnyElement {
    let count = unread(item).flatten();
    div()
        .flex()
        .items_center()
        .gap_1()
        .text_color(color)
        .child(icon(item, color))
        .when_some(count, |content, count| content.child(count.to_string()))
        .into_any_element()
}

fn icon(item: &TrayItem, color: Rgba) -> AnyElement {
    let known = OVERRIDES.iter().find(|(name, _)| is(item, name));
    if let Some(&(_, icon)) = known {
        return static_icon(icon, color).into_any_element();
    }
    match &item.icon {
        Some(TrayIcon::Svg(path)) => svg()
            .external_path(path.clone())
            .size(rems(1.))
            .flex_shrink_0()
            .text_color(color)
            .into_any_element(),
        Some(TrayIcon::Raster(image)) => img(ImageSource::Render(image.clone()))
            .size(rems(1.))
            .flex_shrink_0()
            .into_any_element(),
        None => div()
            .child(
                item.title
                    .chars()
                    .next()
                    .unwrap_or('?')
                    .to_uppercase()
                    .to_string(),
            )
            .into_any_element(),
    }
}

/// The height `rows` takes, so the dropdown's can be animated before layout.
pub fn menu_height(entries: &[MenuEntry]) -> f32 {
    (entries.iter())
        .map(|entry| match entry.kind {
            EntryKind::Separator => SEPARATOR_HEIGHT,
            _ => ROW_HEIGHT + menu_height(&entry.children),
        })
        .sum()
}

pub type OnClick = Rc<dyn Fn(i32, &mut Window, &mut App)>;

/// A menu's entries, one per row. Submenus are shown inline, indented below their label.
pub fn rows(entries: &[MenuEntry], depth: usize, on_click: &OnClick) -> Vec<AnyElement> {
    // Labels line up if any entry at this level has a check or radio mark.
    let marks = (entries.iter())
        .any(|entry| matches!(entry.kind, EntryKind::Check(_) | EntryKind::Radio(_)));
    let mut rows = Vec::new();
    for entry in entries {
        if entry.kind == EntryKind::Separator {
            rows.push(
                div()
                    .h(px(SEPARATOR_HEIGHT))
                    .flex_shrink_0()
                    .flex()
                    .items_center()
                    .px_2()
                    .child(div().h(px(1.)).w_full().bg(theme::SEPARATOR))
                    .into_any_element(),
            );
            continue;
        }
        let checked = matches!(entry.kind, EntryKind::Check(true) | EntryKind::Radio(true));
        let submenu = !entry.children.is_empty();
        let interactive = !submenu && entry.enabled;
        let row = div()
            .id(("tray-menu", entry.id as usize))
            .when(interactive, |row| {
                row.relative()
                    .child(background("background").radius(px(6.)))
            })
            .h(px(ROW_HEIGHT))
            .flex_shrink_0()
            .pl(px(8. + INDENT * depth as f32))
            .pr_2()
            .flex()
            .items_center()
            .gap_2()
            .rounded(px(6.))
            .text_size(px(14.))
            .when(marks, |row| {
                row.child(div().size(rems(1.)).flex_shrink_0().when(checked, |mark| {
                    mark.child(static_icon(Icon::Check, theme::FOREGROUND))
                }))
            })
            .child(div().truncate().child(entry.label.clone()));
        let row = if !interactive {
            row.text_color(theme::MUTED)
        } else {
            let (on_click, id) = (on_click.clone(), entry.id);
            row.text_color(theme::FOREGROUND)
                .cursor_pointer()
                .on_click(move |_, window, cx| on_click(id, window, cx))
        };
        rows.push(row.into_any_element());
        if submenu {
            rows.extend(self::rows(&entry.children, depth + 1, on_click));
        }
    }
    rows
}
