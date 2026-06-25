{
  pkgs,
  config,
  ...
}: let
  shader = pkgs.writeTextFile {
    name = "shader.glsl";
    text = builtins.readFile ./ghostty-shader.glsl;
  };
in {
  programs.ghostty = {
    enable = true;
    enableFishIntegration = config.programs.fish.enable;

    settings = {
      # --- Appearance: matches kitty ---
      theme = "Everforest Dark Hard";
      font-family =
        if pkgs.stdenv.isLinux
        then "FiraCode Nerd Font"
        else "Fira Code";
      font-size = 12;

      # kitty: background_opacity = 0.9
      background-opacity = 0.9;

      # kitty: cursor_trail 1 / cursor_trail_decay — replicated via the GLSL
      # cursor-trail shader (ghostty has no native cursor trail).
      custom-shader = "${shader}";

      # kitty: hide_window_decorations yes on Linux, no elsewhere.
      window-decoration =
        if pkgs.stdenv.isLinux
        then "none"
        else "auto";

      # kitty: confirm_os_window_close = 0
      confirm-close-surface = false;

      # kitty: disable_ligatures = never -> ligatures always on (ghostty default,
      # left explicit for parity).

      # Advanced terminal features used heavily:
      #   * Kitty graphics protocol (images) — enabled by default in ghostty.
      #   * Kitty keyboard protocol — enabled by default in ghostty.
      # No setting is required to turn these on; we just avoid disabling them.

      # kitty: clear_all_shortcuts yes, then re-add only the bindings below.
      keybind = [
        "clear"

        # kitty: map kitty_mod+equal / kitty_mod+minus change_font_size all +/-2.0
        # (kitty_mod defaults to ctrl+shift)
        "ctrl+shift+equal=increase_font_size:2"
        "ctrl+shift+minus=decrease_font_size:2"

        # kitty: map f11 toggle_fullscreen
        "f11=toggle_fullscreen"

        # kitty: copy/paste
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"
      ];
    };
  };
}
