{
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
  ];

  config = {
    home.shellAliases = {
      "p" = "cd ~/projects/playground";
      "t" = "cd /tmp";
      "q" = "exit";
      "ns" = "nix search nixpkgs";
    };
  };
}
