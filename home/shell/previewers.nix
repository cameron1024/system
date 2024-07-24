{pkgs, ...}: {
  home.packages = with pkgs; [
    mdcat
    slides
    # inlyne
    tdf
  ];
}
