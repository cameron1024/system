{pkgs, ...}: {
  home.packages = [pkgs.goose-cli];
  programs.nixvim = {
    extraPlugins = [pkgs.vimPlugins.goose];
  };
}
