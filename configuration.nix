{ pkgs, hardware, ... }:

let
  linux = pkgs.linuxPackages_6_5;
in
{
  imports = [
    hardware
    ./modules/wm
    ./modules/hardware/usb_wake.nix
    
    ./modules/tools
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "python-2.7.18.6"
  ];

  nix = {
    package = pkgs.nixVersions.stable; # or versioned attributes like nixVersions.nix_2_8
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      trusted-users = [ "root" "@wheel" ];
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };

  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.kernelPackages = linux;

  systemd.coredump.enable = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";



  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;


  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.defaultUserShell = pkgs.fish;
  users.users.cameron = {
    isNormalUser = true;
    description = "cameron";
    extraGroups = [ "networkmanager" "wheel" "adbusers" "docker" "plugdev" "audio" "video" "sound" ];
  };
  users.groups.adbusers = { };
  users.groups.docker = { };
  users.groups.plugdev = { };

  environment.systemPackages = with pkgs; [
    firefox
    fish
    git
    git-lfs
    vim
    linux.perf

    killall

    # should these be in gnome? or hyprland?
    xdg-desktop-portal-wlr
    xdg-desktop-portal

    linux.system76-scheduler

    logiops
  ];

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;


  environment.variables.EDITOR = "nvim";

  /* boot.extraModprobeConfig = pkgs.lib.mkMerge [ */
  /*   # idle audio card after one second */
  /*   "options snd_hda_intel power_save=1" */
  /*   # enable wifi power saving (keep uapsd off to maintain low latencies) */
  /*   "options iwlwifi power_save=1 uapsd_disable=1" */
  /* ]; */



  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  programs.fish.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leavecatenate(variables, "bootdev", bootdev)
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?

  services.deluge.enable = true;

  fonts.packages = with pkgs; [
    fira

    (nerdfonts.override {
      fonts = [ "FiraCode" "DroidSansMono" ];
    })
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
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;
  services.thermald.enable = true;

  networking = {
    dhcpcd.wait = "background";
    dhcpcd.extraConfig = "noarp";
  };
}
