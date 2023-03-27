local wezterm = require 'wezterm'

return {
  font = wezterm.font 'FiraCode Nerd Font',
  harfbuzz_features = {"zero" , "ss01", "cv05"},
  enable_tab_bar = false,
  window_padding = { left = 0, right = 0, top = 0, bottom = 0, },
  default_prog = { 'fish', '--command', 'tmux' },
  color_scheme = "Catppuccin Mocha",

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
