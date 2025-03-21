{
  machine,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    git-cliff
    difftastic
    mergiraf
    delta
  ];

  programs.lazygit = {
    enable = true;
    settings = {
      git = {
        paging = {
          externalDiffCommand = "difft --color=always";
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

    # "github diff"
    "ghd" = "git diff origin/main...HEAD";

    "gb" = "gh browse";
    "gpv" = "gh pr view --web";
  };

  programs.fish.shellAbbrs = {
    "gr" = "cd $(git rev-parse --show-toplevel)";
  };

  programs.git = {
    enable = true;

    lfs.enable = true;

    userName = machine.user.name;
    userEmail = machine.user.email;

    # delta.enable = true;
    difftastic.enable = true;
    difftastic.display = "inline";

    extraConfig = {
      core = {
        editor = "nvim";
        attributesFile = "~/.gitattributes";
      };
      init.defaultBranch = "master";

      pull.rebase = false;

      push = {
        default = "current";
        autoSetupRemote = true;
      };

      merge."mergiraf" = {
        name = "mergiraf";
        driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
      };
    };
  };

  programs.gh = {
    enable = true;
  };

  programs.gh-dash.enable = true;

  home.file.".gitattributes".text = ''
    *.java merge=mergiraf
    *.rs merge=mergiraf
    *.go merge=mergiraf
    *.js merge=mergiraf
    *.jsx merge=mergiraf
    *.json merge=mergiraf
    *.yml merge=mergiraf
    *.yaml merge=mergiraf
    *.toml merge=mergiraf
    *.html merge=mergiraf
    *.htm merge=mergiraf
    *.xhtml merge=mergiraf
    *.xml merge=mergiraf
    *.c merge=mergiraf
    *.cc merge=mergiraf
    *.h merge=mergiraf
    *.cpp merge=mergiraf
    *.hpp merge=mergiraf
    *.cs merge=mergiraf
    *.dart merge=mergiraf
    *.scala merge=mergiraf
    *.sbt merge=mergiraf
    *.ts merge=mergiraf
    *.py merge=mergiraf
  '';
}
