hardware: { config, pkgs, ... }:

let
  linux = pkgs.linuxPackages_6_0;
in
{
  imports = [
    hardware
    ./modules/gnome
  ];

  nix = {
    package = pkgs.nixVersions.stable; # or versioned attributes like nixVersions.nix_2_8
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelPackages = linux;

  networking.hostName = "nixos"; # Define your hostname.
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  time.timeZone = "Europe/London";

  console.keyMap = "uk";

  services.printing.enable = true;

  users.defaultUserShell = pkgs.fish;
  users.users.cameron = {
    isNormalUser = true;
    description = "cameron";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "docker" "plugdev" ];
  };
  users.groups.adbusers = { };
  users.groups.docker = { };
  users.groups.plugdev = { };


  environment.systemPackages = with pkgs; [
    firefox
    kate
    fish
    git
    gnome.gnome-tweaks
    gnome.dconf-editor
    vim
    linux.perf
    gnomeExtensions.gsconnect
    xdg-desktop-portal-wlr
    xdg-desktop-portal
  ];

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  environment.variables.EDITOR = "nvim";


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leavecatenate(variables, "bootdev", bootdev)
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

  services.deluge.enable = true;

  fonts.fonts = with pkgs; [
    nerdfonts
  ];

  services.postgresql = {
    enable = true;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all 127.0.0.1/32 trust
      host all all ::1/128 trust
    '';
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.adb.enable = true;
  services.udev.packages = [
    pkgs.android-udev-rules
  ];
}
