{
  pkgs,
  lib,
  isDarwin,
  ...
}: let
  packages = with pkgs; [
    slack
    whatsapp-for-linux
    telegram-desktop
    discord
  ];
in {
  home.packages = lib.mkIf (!isDarwin) packages;

  xdg.configFile."BetterDiscord/themes/Catppuccin.theme.css".source = ./catppuccin-discord.css;

  xdg.configFile."discord/settings.json".source = ./discord-settings.json;

  # run `nix run nixpkgs#betterdiscordctl install`
}
