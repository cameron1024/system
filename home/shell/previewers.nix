{pkgs, ...}: {
  home.packages = with pkgs; [
    mdcat
    slides
    tdf
    jnv
  ];
}
