{
  imports = [./fish ./nushell ./git ./zoxide.nix ./fzf.nix];

  config = {
    home.shellAliases = {
      "t" = "cd /tmp";
      "q" = "exit";
    };
  };
}
