//! Everforest dark, hard contrast. Widgets use semantic roles; the full palette is available
//! for future UI without scattering color literals throughout the shell.
//! Palette: https://github.com/sainnhe/everforest/blob/master/autoload/everforest.vim

use gpui::Rgba;

const fn rgb(hex: u32) -> Rgba {
    Rgba {
        r: ((hex >> 16) & 0xff) as f32 / 255.,
        g: ((hex >> 8) & 0xff) as f32 / 255.,
        b: (hex & 0xff) as f32 / 255.,
        a: 1.,
    }
}

#[allow(dead_code)]
pub mod palette {
    use super::*;

    pub const BG_DIM: Rgba = rgb(0x1e2326);
    pub const BG0: Rgba = rgb(0x272e33);
    pub const BG1: Rgba = rgb(0x2e383c);
    pub const BG2: Rgba = rgb(0x374145);
    pub const BG3: Rgba = rgb(0x414b50);
    pub const BG4: Rgba = rgb(0x495156);
    pub const BG5: Rgba = rgb(0x4f5b58);
    pub const BG_RED: Rgba = rgb(0x493b40);
    pub const BG_VISUAL: Rgba = rgb(0x4c3743);
    pub const BG_YELLOW: Rgba = rgb(0x45443c);
    pub const BG_GREEN: Rgba = rgb(0x3c4841);
    pub const BG_BLUE: Rgba = rgb(0x384b55);
    pub const BG_PURPLE: Rgba = rgb(0x463f48);
    pub const FG: Rgba = rgb(0xd3c6aa);
    pub const RED: Rgba = rgb(0xe67e80);
    pub const ORANGE: Rgba = rgb(0xe69875);
    pub const YELLOW: Rgba = rgb(0xdbbc7f);
    pub const GREEN: Rgba = rgb(0xa7c080);
    pub const AQUA: Rgba = rgb(0x83c092);
    pub const BLUE: Rgba = rgb(0x7fbbb3);
    pub const PURPLE: Rgba = rgb(0xd699b6);
    pub const GREY0: Rgba = rgb(0x7a8478);
    pub const GREY1: Rgba = rgb(0x859289);
    pub const GREY2: Rgba = rgb(0x9da9a0);
    pub const STATUSLINE1: Rgba = rgb(0xa7c080);
    pub const STATUSLINE2: Rgba = rgb(0xd3c6aa);
    pub const STATUSLINE3: Rgba = rgb(0xe67e80);
}

/// Darker than the palette's BG_DIM: near-black surfaces read as one liquid with the bezel.
/// Translucent over the compositor's blur.
pub const BACKGROUND: Rgba = Rgba {
    a: 0.65,
    ..rgb(0x151a1c)
};
pub const FOREGROUND: Rgba = palette::FG;
pub const MUTED: Rgba = palette::GREY1;

/// Between modules within a section.
pub const SEPARATOR: Rgba = Rgba {
    a: 0.2,
    ..palette::FG
};

pub const SCROLLBAR: Rgba = Rgba {
    a: 0.3,
    ..palette::FG
};

/// A translucent tint, so hovered modules stay part of the liquid.
pub const MODULE_HOVER: Rgba = Rgba {
    a: 0.08,
    ..palette::FG
};
pub const POWER_ACCENT: Rgba = palette::ORANGE;
pub const CLOCK_ACCENT: Rgba = palette::GREEN;
pub const VOLUME_ACCENT: Rgba = palette::BLUE;
pub const SYSTEM_ACCENT: Rgba = palette::PURPLE;
pub const BRIGHTNESS_ACCENT: Rgba = palette::YELLOW;
pub const CAFFEINE_ACCENT: Rgba = palette::RED;
pub const NOTIFICATION_ACCENT: Rgba = palette::PURPLE;
/// Tray icons come from other apps, so they're neutral rather than claiming an accent.
pub const TRAY_ACCENT: Rgba = palette::FG;

/// A module whose dropdown is open.
pub const SELECTED: Rgba = Rgba {
    a: 0.14,
    ..palette::FG
};

/// A notification in the dropdown.
pub const CARD: Rgba = Rgba {
    a: 0.05,
    ..palette::FG
};
pub const BATTERY_ACCENT: Rgba = palette::AQUA;
pub const WARNING: Rgba = palette::ORANGE;
pub const CRITICAL: Rgba = palette::RED;

/// Resource usage: green below 40%, orange below 80%, red from 80%.
pub fn usage(percent: u32) -> Rgba {
    match percent {
        0..40 => palette::GREEN,
        40..80 => WARNING,
        _ => CRITICAL,
    }
}
