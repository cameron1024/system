{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./fonts.nix
  ];

  config = {

    nixpkgs = {
        system = "aarch64-darwin";
        config = {allowUnfree = true;};
        overlays = [(import ../overlays/utils.nix)];
    };
    
    environment.systemPackages = with pkgs; [
      karabiner-elements
    ];

    system.keyboard.enableKeyMapping = true;
    system.keyboard.remapCapsLockToControl = true;

    system.defaults.dock.expose-animation-duration = 10.0;

    # nixpkgs.hostPlatform = "aarch64-darwin";
    services.nix-daemon.enable = true;

    users.users.cameron = {
      description = "cameron";
      home = "/Users/cameron";
    };

    homebrew = {
      enable = true;
      brews = ["fvm"];
      taps = ["leoafarias/fvm"];
    };

    environment.variables = {
      ANDROID_HOME = "/Users/cameron/Library/Android/sdk";
    };

    home-manager.users.cameron = {
      programs.fish.interactiveShellInit = ''
        set PATH $PATH ~/fvm/default/bin
      '';
      programs.nushell = {
        shellAliases = {
          brew = "/opt/homebrew/bin/brew";
        };
      };
    };
  };
}
