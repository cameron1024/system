{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [mdx];
    
    extraConfigLua = ''
      require "lz.n".load {
        {
          "mdx",
          ft = "mdx",
          after = function() require "mdx".setup() end,
        }
      }
    '';

    extraFiles."after/ftplugin/markdown.lua".text = ''
      vim.opt_local.shiftwidth = 2
      vim.opt_local.tabstop = 2
      vim.opt_local.conceallevel = 1
    '';



    filetype.extension."mdx" = "mdx";
    # plugins.lsp.servers.marksman.enable = true;
    # plugins.lsp.servers.markdown_oxide.enable = true;
    # plugins.lsp.servers.markdown_oxide.settings.root_markers = [
    #   ".git"
    #   ".obsidian"
    #   ".moxide.toml"
    #   "book.toml"
    # ];

    plugins.render-markdown = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = ["markdown" "typst" "mdx"];
      settings = {
        completions.blink.enabled = true;

        code.enabled = false;
        code.conceal_delimiters = false;
        code.language_name = false;
        code.language_icon = false;

        preview.modes = ["n" "x"];
        preview.hybrid_modes = ["i" "r"];
      };
    };

    # plugins.markview = {
    #   enable = true;
    #   lazyLoad.enable = true;
    #   lazyLoad.settings.ft = ["markdown" "typst"];
    #   settings = {
    #     preview.modes = ["n" "x"];
    #     preview.hybrid_modes = ["i" "r"];
    #   };
    # };

  };
}
