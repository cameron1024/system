{
  pkgs,
  machine,
  ...
}: let
  systemPackages = with pkgs;
    if machine.linux
    then [
      pcmanfm
      gcc
    ]
    else [];
in {
  imports = [
    ./fish
    ./nushell
    ./tmux
    ./prompt
    ./git
    ./zoxide.nix
    ./fzf.nix
    ./direnv.nix
    ./eza.nix
    ./yazi.nix
    ./previewers.nix
    ./nix.nix

    ./system
  ];

  config = {

    programs.bat = {
      enable = true;
      # themes = {
      #   everforest = {
      #     src = pkgs.everforest-collection; 
      #     file = "bat/everforest-soft.tmTheme";
      #   };
      # };
    };
    programs.atuin = {
      enable = true;
      # enableFishIntegration = true;
      settings = {
        filter_mode_shell_up_key_binding = "session";
        enter_accept = true;
      };

      flags = ["--disable-up-arrow"];
    };

    home.shellAliases = {
      "p" = "cd ~/projects/playground";
      "t" = "cd /tmp";
      "n" = "cd ~/notes";
      "q" = "exit";
      "ns" = "nix search nixpkgs";
    };

    home.packages = with pkgs;
      [
        # general utilities
        bash
        ripgrep
        killall
        tree
        fd
        coreutils
        gnumake
        tokei

        #data stuff
        sq
        jq
        jaq

        # network stuff
        trippy
        hurl
        gping
        xh
        speedtest-rs

        # text stuff
        sad

        ripdrag

        awscli2

        comma
      ]
      ++ systemPackages;
  };
}
