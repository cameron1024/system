{
  pkgs,
  machine,
  ...
}: let
  systemPackages = with pkgs;
    if machine.linux
    then [
      pcmanfm
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
    home.shellAliases = {
      "p" = "cd ~/projects/playground";
      "t" = "cd /tmp";
      "q" = "exit";
      "ns" = "nix search nixpkgs";
    };

    home.packages = with pkgs;
      [
        # general utilities
        killall
        tree
        fd

        #data stuff
        sq
        jq
        jaq
        tabiew

        # network stuff
        trippy
        hurl
        gping
        xh 

        # text stuff
        sad

        ripdrag

        awscli
      ]
      ++ systemPackages;
  };
}
