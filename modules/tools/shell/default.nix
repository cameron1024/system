{ pkgs, username, lib, ... }:

let
  # recentNushell = pkgs.nushell.overrideAttrs (old: rec {
  #   version = "0.88.1";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "nushell";
  #     repo = "nushell";
  #     rev = version;
  #     hash = "sha256-UuKXonAEMX57pZwP37N1FuUtkRE+3xB6Oj30yxSpJk4=";
  #   };
  #
  #   cargoSha256 = "";
  # });
in

{
  imports = [ ./bat ];

  config.home-manager.users.${username} = {
    programs.nushell = {
      enable = true;
      # package = recentNushell;
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
      envFile.source = ./env.nu;
    };

    programs.zoxide = {
      enable = true;
      enableNushellIntegration = true;
    };

    programs.direnv = {
      enable = true;
      enableNushellIntegration = true;
    };

    # programs.carapace = {
    #   enable = true;
    #   enableNushellIntegration = true;
    # };

    programs.starship = {
      enable = true;
      enableNushellIntegration = true;
      settings = {
        format = "$nix_shell$directory$git_branch$git_metrics$git_state";
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

  };
}
