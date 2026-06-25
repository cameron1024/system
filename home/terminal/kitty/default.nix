{
  pkgs,
  lib,
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
    background_opacity = "0.9";

    # The config lives in the read-only nix store and only ever changes on a
    # rebuild, so there is no point watching it at runtime. Disabling this also
    # works around https://github.com/kovidgoyal/kitty/issues/10102, where the
    # watcher recursively inotify-watches every dir an included config lives in
    # (e.g. all of /nix/store), exhausting the kernel's inotify watch limit.
    auto_reload_config = "no";
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

    hide_window_decorations ${
      if pkgs.stdenv.isLinux
      then "yes"
      else "no"
    }

    font_size 12.0
  '';

  # Since auto_reload_config is disabled above, kitty won't pick up config
  # changes on its own. Whenever this generation is activated (i.e. on every
  # `nixos-rebuild switch`), signal any running kitty instances to reload their
  # config. SIGUSR1 triggers a reload regardless of auto_reload_config.
  home.activation.reloadKitty = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -USR1 -x kitty || true
  '';
}
