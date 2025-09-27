{pkgs, ...}: 
  let 
    mdx = pkgs.vimUtils.buildVimPlugin {
        pname = "mdx.nvim";
        version = "0.0.0";
        src = pkgs.fetchFromGitHub {
          owner = "davidmh";
          repo = "mdx.nvim";
          rev = "464a74be368dce212cff02f6305845dc7f209ab3";
          hash = "sha256-jpMcrWx/Rg9sMfkQFXnIM8VB5qRuSB/70wuSh6Y5uFk=";
        };
      };
    # iwe = pkgs.vimUtils.buildVimPlugin {
    #     pname = "iwe.nvim";
    #     version = "0.0.0";
    #     src = pkgs.fetchFromGitHub {
    #       owner = "iwe-org";
    #       repo = "iwe.nvim";
    #       rev = "b415c7e49e6a65147d03373bd6871d181f7ae5df";
    #       hash = "sha256-AbaGYiWJWwn2+rs96ezIlAKYHQUjRtQt74UnuPzvudg=";
    #     };
    #   };
  in
{
  extraPlugins = with pkgs.vimPlugins; [
    mdx
    # iwe
    vim-table-mode
  ];

  extraConfigLua = ''
    require "lz.n".load {
      {
        "mdx",
        ft = "mdx",
        after = function() require "mdx".setup() end,
      },
      -- {
      --   "iwe",
      --   ft = "markdown",
      --   after = function()
      --     require "iwe".setup {
      --       lsp = {
      --         root_markers = { ".iwe" },
      --         auto_format_on_save = false,
      --       },
      --       mappings = {
      --         enable_markdown_mappings = false,
      --       },
      --     }
      --   end,
      -- },
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
}
