{
  inputs,
  machine,
  ...
}: {
  imports = [inputs.ags.homeManagerModules.default];

  programs.ags = {
    enable = machine.wm.hyprland.enable;
    configDir = ./ags;
    extraPackages = [];
  };
}
