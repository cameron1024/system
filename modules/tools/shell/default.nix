{ pkgs, ... }:

{
  home-manager.users.cameron = {

    # home.packages = with pkgs; [
    #   zoxide
    # ];

    programs.zoxide.enable = true;
    programs.zoxide.enableNushellIntegration = true;

    programs.direnv.enable = true;
    programs.direnv.enableNushellIntegration = true;

    programs.nushell = {
      enable = true;
      shellAliases = {
        e = "nvim";
        ed = "neovide --multigrid";
        p = "cd ~/projects/playground";
        x = "./x.py";
        ls = "exa -l";
        dev = "nix develop --command fish";
        dr = "direnv reload";
        rs = "rust-script";
        t = "cd /tmp";
        g = "z";
        q = "exit";
      };
      configFile.source = ./config.nu;
    };
  };
}
