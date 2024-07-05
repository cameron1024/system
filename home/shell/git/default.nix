{machine, ...}: {
  home.shellAliases = {
    "gc" = "git commit -am";
    "gs" = "git switch";
    "gpl" = "git pull";
    "gps" = "git push";
    "gf" = "git fetch";
    "grst" = "git reset --hard HEAD";

    "gb" = "gh browse";
    "gr" = "cd $(git rev-parse --show-toplevel)";
  };
  programs.git = {
    enable = true;

    userName = machine.user.name;
    userEmail = machine.user.email;

    delta = {
      enable = true;
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.gh-dash.enable = true;
}
