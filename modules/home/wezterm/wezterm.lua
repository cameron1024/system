local wezterm = require 'wezterm'

return {

  color_scheme = "Catppuccin Mocha",

  font = wezterm.font_with_fallback {
    'FiraCode Nerd Font',
  },
  harfbuzz_features = { "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08", "calt", "dlig", "liga" },

  enable_tab_bar = false,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0, },

  default_prog = { 'tmux' },

  hide_mouse_cursor_when_typing = false,
  warn_about_missing_glyphs = false,
  window_close_confirmation = "NeverPrompt",

  enable_kitty_keyboard = true,

  -- :(
  -- enable_wayland = false,

  keys = {
    {
      key = "Enter",
      mods = "ALT",
      action = wezterm.action.DisableDefaultAssignment,
    },
    {
      key = "q",
      mods = "SUPER",
      action = wezterm.action.DisableDefaultAssignment,
    },
    {
      key = "F11",
      action = wezterm.action.ToggleFullScreen,
    },
  },
}
