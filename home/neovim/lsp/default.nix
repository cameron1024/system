{pkgs, ...}: {

  # TODO: https://github.com/WilliamHsieh/overlook.nvim 

  plugins.fidget.enable = true;
  plugins.fidget.lazyLoad.enable = true;
  plugins.fidget.lazyLoad.settings.event = ["LspAttach"];

  extraPlugins = [
    pkgs.vimPlugins.plenary-nvim
    (pkgs.callPackage ./lsp-tiny-code-action.nix {})
  ];
  extraConfigLua = ''
    local keymap = require 'lz.n'.keymap {
      "tiny-code-action",
      after = function()
        require 'tiny-code-action'.setup {
          backend = "difftastic",
          picker = "snacks",
        }
      end,
    }

    keymap.set(
      { "n", "v" },
      "gra",
      function() require 'tiny-code-action'.code_action() end,
      { desc = "Code actions" }
    )
  '';

  plugins.lsp = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.event = ["BufReadPost" "BufNewFile"];

    keymaps.diagnostic = {
      "<C-n>" = "goto_next";
      "<C-b>" = "goto_prev";
    };
    keymaps.lspBuf = {
      "K" = "hover";
    };
    keymaps.extra = [
      {
        key = "<leader>i";
        action.__raw = ''
          function()
            local lsp = vim.lsp
            lsp.inlay_hint.enable(not lsp.inlay_hint.is_enabled())
          end
        '';
      }
      # {
      #   key = "<leader>d";
      #   action.__raw = ''
      #     function()
      #       local cfg = vim.diagnostic.config()
      #       if cfg.virtual_lines == false then
      #         cfg.virtual_lines = { current_line = true }
      #       else
      #         cfg.virtual_lines = false
      #       end
      #       vim.diagnostic.config(cfg)
      #     end
      #   '';
      # }
    ];

    servers.ast_grep.enable = true;
    servers.nixd.enable = true;
    servers.nil_ls.enable = true;
    servers.bashls.enable = true;
    servers.lemminx.enable = true;
    servers.nushell.enable = true;
    servers.qmlls.enable = true;
    servers.cue.enable = true;
    servers.asm_lsp.enable = true;
    servers.clangd.enable = true;
    servers.scheme_langserver.enable = true;

  };


}
