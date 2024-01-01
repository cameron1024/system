#!/usr/bin/env bash

KITTY_STATUS=$(ps -fC alacritty | grep "dropdown")
[ -z "${KITTY_STATUS}" ] && kitty --class Alacritty,dropdown -T dropdown-alacritty -e tmux
