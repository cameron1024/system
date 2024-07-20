{machine, ...}: let
  colors = with machine.colorscheme; ''
    @define-color bg ${base01};
    @define-color fg ${base04};
  '';
in {
  programs.waybar = {
    enable = true;
    style = colors + (builtins.readFile ./style.css);

    settings = {
      topBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = map (d: d.name) machine.displays;

        modules-left = [];
        modules-center = ["clock"];
        modules-right = ["tray"];
      };
    };
  };
}
