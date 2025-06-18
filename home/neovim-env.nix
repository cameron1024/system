{pkgs, ...}: {
  home.shellAliases = {
    "e" = "nvim";
    "ed" = "nvim +DiffviewOpen";
    "nv" = "neovide --fork";
  };

  home.sessionVariables = {
    "EDITOR" = "nvim";
    "MANPAGER" = "nvim +Man!";
  };

  home.packages = with pkgs; [
    typst
    neovide
  ];
}
