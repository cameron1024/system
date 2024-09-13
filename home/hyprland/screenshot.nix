{pkgs, lib, machine, ...}: {
  home.packages = lib.mkIf machine.linux (with pkgs; [
    hyprshot
    jq
    grim
    slurp
    wl-clipboard
    libnotify
  ]);

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER SHIFT, s, exec, hyprshot -m region"
    ];
  };
}
