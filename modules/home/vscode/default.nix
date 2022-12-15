{ pkgs, config, lib, ... }:

let
  arrows = {
    "h" = "left";
    "j" = "down";
    "k" = "up";
    "l" = "right";
  };

in
{
  programs.vscode = {
    enable = true;

    extensions = with pkgs.vscode-extensions; [
      jdinhlife.gruvbox

      matklad.rust-analyzer

      asvetliakov.vscode-neovim

      jnoortheen.nix-ide
    ];

    userSettings = {
      "vscode-neovim.neovimExecutablePaths.linux" = "nvim";
    };
  };

}
