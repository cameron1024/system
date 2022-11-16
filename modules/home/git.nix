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
      core = {
        editor = "nvim";
      };

      init = {
        defaultBranch = "master";
      };

      push = {
        default = "current";
      };
    };
  };
}
