local wezterm = require 'wezterm'

local config = wezterm.config_builder()

config.enable_tab_bar = false
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

config.color_scheme = 'Everforest Dark Hard (Gogh)'
config.font = wezterm.font 'FiraCode Nerd Font'

config.enable_kitty_keyboard = true

return config
