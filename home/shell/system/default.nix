{pkgs, ...}: {
  # home.packages is the home-manager equivalent of the nixos option `environment.systemPackages`
  home.packages = with pkgs; [
    bottom
    killall
  ];
}
