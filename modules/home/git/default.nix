{pkgs, ...}: let
  abbrs = {
    gs = "git switch";
    gps = "git push";
    gpl = "git fetch && git pull";
    grst = "git reset --hard HEAD";
  };
in {
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

    lfs.enable = true;
  };

  programs.gh = {
    enable = true;
    settings = {
      version = 1;
      extensions = with pkgs; [
        gh-dash
      ];
    };
  };

  programs.nushell.shellAliases = abbrs;
  programs.fish.shellAbbrs = abbrs // {gc = "git add -A && git commit -m";};

  programs.nushell.extraConfig = ''
    def gc [message] {
      git add -A;
      git commit -m $message;
      null
    }
  '';

  programs.gitui.enable = true;
  programs.lazygit.enable = true;
}
