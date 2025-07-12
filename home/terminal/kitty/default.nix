{
  pkgs,
  osConfig,
  ...
}: let
  package =
    if osConfig == null
    then
      pkgs.wrapWithNixGL {
        package = pkgs.kitty;
        name = "kitty";
      }
    else pkgs.kitty;
in {
  programs.kitty.enable = true;
  programs.kitty.package = package;
  programs.kitty.themeFile = "everforest_dark_hard";

  programs.kitty.font.name =
    if pkgs.stdenv.isLinux
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
    map f11 toggle_fullscreen

    map ctrl+shift+c copy_to_clipboard
    map ctrl+shift+v paste_from_clipboard

    cursor_trail 1
    cursor_trail_decay 0.1 0.2

    hide_window_decorations yes

    font_size 12.0
  '';
}
