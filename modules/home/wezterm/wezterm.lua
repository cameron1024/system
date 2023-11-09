local wezterm = require 'wezterm'

return {
  font = wezterm.font 'FiraCode Nerd Font',
  harfbuzz_features = {"zero" , "ss01", "cv05"},
  enable_tab_bar = false,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0, },
  -- default_prog = { 'fish', '--command', 'tmux' },
  default_prog = { 'nu' },
  color_scheme = "Catppuccin Mocha",
  hide_mouse_cursor_when_typing = false,
  warn_about_missing_glyphs = false,

  enable_kitty_keyboard = true,

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
