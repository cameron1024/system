{ pkgs, ...}:
let 
  git-conflict = import ../../../home/nvim/custom_plugins/git-conflict.nix { inherit pkgs; };
in
{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = git-conflict;
      config = "lua require 'git-conflict'.setup {}";
    }

    {
      plugin = octo-nvim;
      config = "lua require 'octo'.setup {}";
    }

    git-blame-nvim
    
  ];
}
