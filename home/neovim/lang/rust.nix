{pkgs, ...}: let
  ferris = pkgs.vimUtils.buildVimPlugin {
    pname = "ferris.nvim";
    version = "0.0.0";

    src = pkgs.fetchFromGitHub {
      owner = "vxpm";
      repo = "ferris.nvim";
      rev = "4e6444d3f5ebf58632e4d7ebffc4b1e106205ef7";
      hash = "sha256-Z1FpeJFs68vMjBZ2q+x2on8tPrafCoik0kOnLDiLqIA=";
    };
  };
in {
    plugins.lsp.servers.rust_analyzer.enable = true;
    plugins.lsp.servers.rust_analyzer.installCargo = false;
    plugins.lsp.servers.rust_analyzer.installRustc = false;

    extraPlugins = [ferris];
    autoCmd = [
      {
        command = "lua require 'ferris'.setup()";
        event = "FileType";
        pattern = "rust";
      }
    ];

    keymaps = [
      {
        key = "<C-p>";
        action.__raw = "function() require 'ferris.methods.open_parent_module'() end";
      }
    ];

    plugins.crates = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = "toml";
    };
}
