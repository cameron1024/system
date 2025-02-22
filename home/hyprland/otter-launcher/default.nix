{pkgs, ...}: {
  home.packages = [
    (pkgs.callPackage ./pkg.nix {})
  ];

  xdg.configFile."otter-launcher/config.toml".source = ./config.toml;

  wayland.windowManager.hyprland.settings = let
    class = "kitty-otter";
  in {
    bind = [
      "SUPER, p, exec, kitty --app-id=${class} otter-launcher"
    ];

    windowrulev2 = [
      "float, class:${class}"
      "center, class:${class}"
      "size 500 300, class:${class}"
    ];
  };
}
