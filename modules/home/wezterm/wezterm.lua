local wezterm = require 'wezterm'

return {
  font = wezterm.font 'Monaspace Krypton',
  -- harfbuzz_features = {"zero" , "ss01", "cv05"},
  enable_tab_bar = false,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0, },
  default_prog = { 'tmux' },
  color_scheme = "Catppuccin Mocha",
  hide_mouse_cursor_when_typing = false,
  warn_about_missing_glyphs = false,

  enable_kitty_keyboard = true,

  -- weird issue about not working on hyprland
  enable_wayland = false,

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
