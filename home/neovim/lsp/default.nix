{pkgs, ...}: {
  programs.nixvim = {
    diagnostics = {
      virtual_lines.current_line = true;
      virtual_text = false;
    };

    plugins.fidget.enable = true;
    plugins.fidget.lazyLoad.enable = true;
    plugins.fidget.lazyLoad.settings.event = ["LspAttach"];

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
        "gd" = "definition";
        "gt" = "type_definition";
        "gi" = "implementation";
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
        {
          key = "<leader>d";
          action.__raw = ''
            function()
              local cfg = vim.diagnostic.config()
              if cfg.virtual_lines == false then
                cfg.virtual_lines = { current_line = true }
              else
                cfg.virtual_lines = false
              end
              vim.diagnostic.config(cfg)
            end
          '';
        }
      ];

      servers.marksman.enable = true;
      servers.nixd.enable = true;
      servers.nil_ls.enable = true;
      servers.ts_ls.enable = true;
      servers.tinymist.enable = true;
      servers.bashls.enable = true;
      servers.lemminx.enable = true;

      servers.dartls.enable = true;
      servers.dartls.settings.showTodos = false;
    };

    extraPlugins = [
      (pkgs.callPackage ./lsp-tiny-code-action.nix {})
    ];

    extraConfigLua = ''
      require 'lz.n'.load {
        {
          "tiny-code-action",
          lazy = true,
          keys = {
            { "gra", function() require 'tiny-code-action'.code_action() end }
          },
          after = function()
            require 'tiny-code-action'.setup {
              backend = "difftastic",
              picker = "snacks",
            }
          end,

        }
      }
    '';
  };
}
