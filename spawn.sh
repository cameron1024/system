#! /usr/bin/env sh

niri msg action spawn -- kitty --class "kitty-btm-monitor" btm
niri msg action spawn -- qutebrowser --target window ":set window.title_format 'ytm-monitor'" https://music.youtube.com
