{
  pkgs,
  hardware,
  boot,
  hostname,
  inputs,
  swapDevices,
  ...
}: let
  linux = pkgs.linuxPackages_6_9;
in {
  imports = [
    hardware

    ./fonts.nix
    ./opengl.nix

    ../devices
    ../../modules/wm
  ];

  programs.nix-index = {
    enableFishIntegration = true;
  };

  programs.nix-ld = {
    enable = true;
  };

  nixpkgs.config.permittedInsecurePackages = [
    "python-2.7.18.6"
  ];

  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = boot;
  boot.kernelPackages = linux;
  # boot.kernelParams = ["i915.force_probe=7d45"];

  services.system76-scheduler.enable = true;

  inherit swapDevices;

  systemd.coredump.enable = true;

  networking.hostName = hostname;
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Configure console keymap
  console.keyMap = "uk";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.cameron = {
    isNormalUser = true;
    description = "cameron";
    extraGroups = ["networkmanager" "wheel" "adbusers" "docker" "plugdev" "audio" "video" "sound"];
  };
  users.groups.adbusers = {};
  users.groups.docker = {};
  users.groups.plugdev = {};

  environment.systemPackages = with pkgs; [
    firefox
    git
    vim
    linux.perf
    cachix

    killall

    logiops
  ];

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

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
