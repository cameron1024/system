{
  programs.starship = {
    enable = true;

    enableFishIntegration = true;
    enableNushellIntegration = true;

    enableTransience = true;

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
