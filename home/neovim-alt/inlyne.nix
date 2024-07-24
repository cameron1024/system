{
  pkgs,
  ...
}: {
  home.packages = [pkgs.inlyne];
  xdg.configFile."inlyne/inlyne.toml".text = ''
    theme = "Dark"

    [font-options]
    regular-font = "Fira Sans"
    monospace-font = "FiraCode Nerd Font"
  '';
}
