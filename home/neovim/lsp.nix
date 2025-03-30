{
  programs.nixvim = {
    diagnostics = {
      virtual_lines.current_line = true;
      virtual_text = false;
    };

    plugins.fidget.enable = true;
    plugins.fidget.lazyLoad.enable = true;
    plugins.fidget.lazyLoad.settings.event = ["BufReadPost" "BufNewFile"];

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
      ];

      servers.rust_analyzer.enable = true;
      servers.dartls.enable = true;
      servers.marksman.enable = true;
      servers.nixd.enable = true;
      servers.nil_ls.enable = true;
      servers.ts_ls.enable = true;
      servers.tinymist.enable = true;
      servers.bashls.enable = true;
      servers.lemminx.enable = true;

      servers.rust_analyzer.installRustc = false;
      servers.rust_analyzer.installCargo = false;
      servers.rust_analyzer.installRustfmt = false;
    };
  };
}
