{ pkgs, ... }:

let 
  wezterm = pkgs.wezterm.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "wez";
      repo = "wezterm";
      fetchSubmodules = true;
      rev = "version";
      hash = "sha256-B6AakLbTWIN123qAMQk/vFN83HHNRSNkqicNRU1GaCc=";
    };
  });
in

{
  home.packages = [ wezterm ];
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
