{ ... }:

{
  programs.git = {
    enable = true;
    userName = "Cameron";
    userEmail = "cameron.studdstreet@gmail.com";

    delta = {
      enable = true;
    };

    aliases = {
      "default-branch" = "!git symbolic-ref refs/remotes/origin/HEAD | cut -d'/' -f4";
      "co" = "checkout";
      "cod" = "checkout '!git default-branch'";
    };

    extraConfig = {
      core.editor = "nvim";
      init.defaultBranch = "master";

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      pull.rebase = "false";
    };
  };

  programs.nushell.shellAliases = {
    gs = "git switch";
    gps = "git push";
    gpl = "git pull";
    grst = "git reset --hard HEAD";
  };
}
