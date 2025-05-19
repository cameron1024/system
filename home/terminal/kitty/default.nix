{machine, ...}: {
  programs.kitty.enable = true;
  programs.kitty.themeFile =
    if machine.colorscheme.name == "gruvbox"
    then "Gruvbox Dark Hard"
    else if machine.colorscheme.name == "everforest"
    then "everforest_dark_hard"
    else null;

  programs.kitty.font.name =
    if machine.linux
    then "FiraCode Nerd Font"
    else "Fira Code";
  programs.kitty.settings = {
    confirm_os_window_close = 0;
    disable_ligatures = "never";
  };

  programs.kitty.extraConfig = ''
    clear_all_shortcuts yes

    map kitty_mod+equal change_font_size all +2.0
    map kitty_mod+minus change_font_size all -2.0

    map ctrl+shift+c copy_to_clipboard
    map ctrl+shift+v paste_from_clipboard

    cursor_trail 1
    cursor_trail_decay 0.1 0.2
  '';
}
