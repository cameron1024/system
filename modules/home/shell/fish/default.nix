{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      e = "nvim";
      p = "cd ~/projects/playground";
      ls = "exa -l";
      dev = "nix develop --command fish";
      dr = "direnv reload";
      da = "direnv allow";
      rs = "rust-script";
      t = "cd /tmp";
      pub = "flutter pub";
      fr = "flutter run";
      f = "flutter";
      g = "z";
      q = "exit";

      cpd = "cp ~/Downloads/";
    };
  };

  # programs.zoxide.enableFishIntegration = true;
  # programs.direnv.enableFishIntegration = true;
  # programs.carapace.enableFishIntegration = true;
  # programs.starship.enableFishIntegration = true;

}
