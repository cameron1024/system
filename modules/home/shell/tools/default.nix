{pkgs, ...}: {
  home.packages = with pkgs; [
    wiki-tui
    mprocs
    speedtest-rs
    hyperfine

    sad
    ripdrag
    fzf-make
    license-cli

    comma

    nix-tree
  ];

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  programs.gitui.enable = true;
  programs.gitui.theme = ./gitui-theme.ron;

  programs.navi.enable = true;
  programs.navi.enableFishIntegration = true;

  programs.fzf.enable = true;
  programs.fzf.enableFishIntegration = true;

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
    settings = {
      opener = {
        text = [
          {
            run = ''nvim "$@"'';
            block = true;
          }
        ];
      };
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      format = "$nix_shell$directory$git_branch$git_metrics$git_state$character";
      right_format = "$time";
      add_newline = true;

      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%H:%M:%S - %a %d/%m";
        style = "dimmed";
      };

      git_branch = {
        disabled = false;
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };

      git_metrics = {
        disabled = false;
      };

      nix_shell = {
        disabled = false;
        format = "$symbol ";
        symbol = "[󰜗]($style)";
      };
    };
  };
}
