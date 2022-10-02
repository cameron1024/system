local wezterm = require 'wezterm'

return {
  font = wezterm.font 'FiraCode Nerd Font',
  harfbuzz_features = { 'calt', 'clig', 'liga' },

  enable_tab_bar = false,
  window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
  },

  keys = {
    {
      key = 'F11',
      action = wezterm.action.ToggleFullScreen,
    },
  },
}
