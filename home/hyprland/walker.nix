{
  inputs,
  machine,
  ...
}: {
  imports = [inputs.walker.homeManagerModules.default];
  config = {
    nix.settings = {
      substituters = ["https://walker.cachix.org"];
      trusted-public-keys = ["walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="];
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        "SUPER, space, exec, walker"
      ];
    };

    programs.walker = {
      enable = true;
      runAsService = true;

      config = {
        terminal = "kitty";
      };
    };
  };
}
