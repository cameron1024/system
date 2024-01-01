{  username, ... }:

{
  imports = [ 
    ./bat
    ./fish
    ./tools
  ];

  config.home-manager.users.${username} = {

    home.sessionVariables = {
      EDITOR = "nvim";
      GIT_EDITOR = "nvim";
      FZF_DEFAULT_COMMAND = "rg --files";
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
      envFile.source = ./env.nu;
    };

    programs.zoxide.enableNushellIntegration = true;
    programs.direnv.enableNushellIntegration = true;
    programs.carapace.enableNushellIntegration = true;
    programs.starship.enableNushellIntegration = true;
  };

}
