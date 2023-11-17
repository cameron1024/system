{ pkgs, username, ... }:

let
  fonts = with pkgs; [
    fira

    (nerdfonts.override {
      fonts = [ "FiraCode" "DroidSansMono" ];
    })
  ];

in

{
  environment.systemPackages = with pkgs; [
    karabiner-elements 
  ];

  fonts.fonts = fonts;
  fonts.fontDir.enable = true;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  system.defaults.dock.expose-animation-duration = 10.0;

  nixpkgs.hostPlatform = "aarch64-darwin";
  services.nix-daemon.enable = true;

  users.users.${username} =  {
    description = username;
    home = "/Users/${username}";
  };

  homebrew = {
    enable = true;
    brews = [ "fvm" ];
    taps = [ "leoafarias/fvm" ];
  };

}
