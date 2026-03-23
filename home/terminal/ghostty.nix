{pkgs, config, ...}: 
let
  shader = pkgs.writeTextFile {
    name = "shader.glsl";
    text = builtins.readFile ./ghostty-shader.glsl;
  };
in
  {

  programs.ghostty = {
    enable = true;
    enableFishIntegration = config.programs.fish.enable;
    settings = {
      theme = "Everforest Dark Hard";
      font-family = "FiraCode Nerd Font";
      custom-shader = "${shader}";
    };
  };
}
