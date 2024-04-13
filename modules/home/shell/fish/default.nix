{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      gr = "cd (git rev-parse --show-toplevel)";
      e = "nvim";
      b = "yazi";
      p = "cd ~/projects/playground";
      ls = "exa -l";
      dev = "nix develop --command fish";
      dr = "direnv reload";
      da = "direnv allow";
      rs = "rust-script";
      t = "cd /tmp";
      g = "z";
      q = "exit";
      n = "cd ~/notes && nvim";

      cpd = "cp ~/Downloads/";

      pub = "flutter pub";
      fr = "flutter run";
      f = "flutter";
      fpg = "flutter pub get";
    };
  };
}
