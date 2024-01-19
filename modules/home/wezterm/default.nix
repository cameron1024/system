{ pkgs, lib, naersk, ... }:

let 
  wezterm = naersk.buildPackage {
    src = pkgs.fetchFromGitHub {
      owner = "wez";
      repo = "wezterm";
      fetchSubmodules = true;
      rev = "4921f139d35590ab35415021221a2a6f5cf10ab3";
      hash = "sha256-WXOsP2rjbT4unc7lXbxbRbCcrc89SfyVdErzFndBF9o=";
    };
  };
  # newWezterm = pkgs.wezterm.overrideAttrs (old: rec {
  #   version = "0.1.0";
  #
  #   src = pkgs.fetchFromGitHub {
  #     owner = "wez";
  #     repo = "wezterm";
  #     fetchSubmodules = true;
  #     rev = "4921f139d35590ab35415021221a2a6f5cf10ab3";
  #     hash = "sha256-WXOsP2rjbT4unc7lXbxbRbCcrc89SfyVdErzFndBF9o=";
  #   };
  #
  #   cargoDeps = old.cargoDeps.overrideAttrs (old: {
  #     name = "wezterm-custom";
  #     inherit src version;
  #     outputHash = "sha256-WXOsP2rjbT4unc7lXbxbRbCcrc89SfyVdErzFndBF9o=";
  #   });
  # });
in

{
  home.packages = [ pkgs.wezterm ];
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
