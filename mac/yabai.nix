{pkgs, ...}: let
  yb = "${pkgs.yabai}/bin/yabai";
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "yb" ''
      ${pkgs.yabai}/bin/yabai $@
    '')
  ];
  services.yabai = {
    enable = false;
    package = pkgs.yabai;
    config = {
      focus_follows_mouse = "autoraise";
      mouse_follows_focus = "off";
      window_placement = "second_child";
      window_opacity = "off";
      window_opacity_duration = "0.0";
      window_topmost = "on";
      window_shadow = "float";
      active_window_opacity = "1.0";
      normal_window_opacity = "1.0";
      split_ratio = "0.50";
      auto_balance = "on";
      mouse_modifier = "fn";
      mouse_action1 = "move";
      mouse_action2 = "resize";
      layout = "bsp";
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
      window_gap = 10;
    };
  };

  services.skhd = {
    enable = false;
    skhdConfig = ''
      fn - l: ${yb} -m space --focus next
      fn - h: ${yb} -m space --focus prev
    '';
  };
}
