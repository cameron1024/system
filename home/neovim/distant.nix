{pkgs, ...}: {
  home.packages = with pkgs; [distant];
  programs.nixvim = {
    plugins.distant = {
      enable = true;
    };
  };
}
