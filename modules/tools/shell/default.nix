{ username, ... }:

{
  imports = [ ./bat ];

  config.home-manager.users.${username} = {
    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        add_newline = true;
        nix_shell.format = "$symbol";
        git_metrics.disabled = false;
        right_format = "$time";
        time.format = "[$time]($style)";
        time.disabled = false;
        time.time_format = "%H:%M:%S - %a %d/%m";
        time.style = "dimmed";
        line_break.disabled = true;
      };
    };

    programs.nushell = {
      enable = true;
      shellAliases = {
        e = "nvim";
        ed = "neovide --multigrid";
        p = "cd ~/projects/playground";
        dev = "nix develop --command fish";
        dr = "direnv reload";
        rs = "rust-script";
        t = "cd /tmp";
        g = "z";
        q = "exit";
        cat = "bat";
      };
      configFile.source = ./config.nu;
    };
  };
}
