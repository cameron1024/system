{
  pkgs,
  username,
  ...
}: {
  imports = [
    ./fonts.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      karabiner-elements
    ];

    system.keyboard.enableKeyMapping = true;
    system.keyboard.remapCapsLockToControl = true;

    system.defaults.dock.expose-animation-duration = 10.0;

    nixpkgs.hostPlatform = "aarch64-darwin";
    services.nix-daemon.enable = true;

    users.users.${username} = {
      description = username;
      home = "/Users/${username}";
    };

    homebrew = {
      enable = true;
      brews = ["fvm"];
      taps = ["leoafarias/fvm"];
    };

    home-manager.users.${username} = {
      programs.nushell = {
        shellAliases = {
          brew = "/opt/homebrew/bin/brew";
        };
      };
    };
  };
}
