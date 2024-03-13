{pkgs, ...}: {
  home.packages = with pkgs; [
    asciiquarium
    cmatrix
    cool-retro-term
  ];
}
