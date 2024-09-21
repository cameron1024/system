{machine, ...}: {
  programs.kitty.enable = true;
  programs.kitty.theme =
    if machine.colorscheme.name == "gruvbox"
    then "Gruvbox Dark Hard"
    else if machine.colorscheme.name == "everforest"
    then "Everforest Dark Hard"
    else null;

  programs.kitty.font.name = "Fira Code NerdFont";
  programs.kitty.settings = {
    confirm_os_window_close = 0;
    disable_ligatures = "never";
  };

  programs.kitty.extraConfig = ''
    clear_all_shortcuts yes

    map kitty_mod+equal change_font_size all +2.0
    map kitty_mod+minus change_font_size all -2.0
  '';

  # xdg.configFile."kitty/themes/current-theme.conf".text = with machine.colorscheme; ''
  #       background ${base00}
  #       foreground ${base07}
  #       selection_background ${base07}
  #       selection_foreground ${base00}
  #       url_color ${base0C}
  #       cursor ${base07}
  #       # active_border_color #665c54
  #       # inactive_border_color #3c3836
  #       # active_tab_background #1d2021
  #       # active_tab_foreground #d5c4a1
  #       # inactive_tab_background #3c3836
  #       # inactive_tab_foreground #bdae93
  #       # tab_bar_background #3c3836
  #
  #       color0 ${base00}
  #       color1 ${base01}
  #       color2 ${base02}
  #       color3 ${base03}
  #       color4 ${base04}
  #       color5 ${base05}
  #       color6 ${base06}
  #       color7 ${base07}
  #       color8 ${base08}
  #       color9 ${base09}
  #       color10 ${base0A}
  #       color11 ${base0B}
  #       color12 ${base0C}
  #       color13 ${base0D}
  #       color14 ${base0E}
  #       color15 ${base0F}
  # '';
}
