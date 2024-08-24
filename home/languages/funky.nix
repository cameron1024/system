{pkgs, ...}: {
  home.packages = with pkgs; [
    fstar
  ];
}

