{
  machine,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    git-cliff
  ];

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          colorArg = "always";
          pager = "delta --dark --paging=never";
        };
      };
    };
  };

  home.shellAliases = {
    "gc" = "git add -A && git commit -m";
    "gca" = "git commit --amend";
    "gs" = "git switch";
    "gpl" = "git pull";
    "gps" = "git push";
    "gf" = "git fetch";
    "grst" = "git reset --hard HEAD";

    "gb" = "gh browse";
  };

  programs.fish.shellAbbrs = {
    "gr" = "cd $(git rev-parse --show-toplevel)";
  };

  programs.git = {
    enable = true;

    lfs.enable = true;

    userName = machine.user.name;
    userEmail = machine.user.email;

    delta.enable = true;

    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "master";

      pull.rebase = false;

      push = {
        default = "current";
        autoSetupRemote = true;
      };
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.gh-dash.enable = true;
}
