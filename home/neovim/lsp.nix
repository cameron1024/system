{pkgs, ... }: {
  programs.nixvim = {
    diagnostics = {
      virtual_lines.current_line = true;
      virtual_text = false;
    };

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
            action.__raw = /* lua */ ''
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
        servers.ts_ls.enable = true;
        servers.tinymist.enable = true;
        servers.bashls.enable = true;
        servers.lemminx.enable = true;

        servers.rust_analyzer.installRustc = false;
        servers.rust_analyzer.installCargo = false;
        servers.rust_analyzer.installRustfmt = false;
    };
  };
  # programs.nixvim.extraConfigLua = /* lua */ ''
  #   vim.lsp.config("rust-analyzer", {
  #     filetypes = { "rust" },
  #     root_markers = { "Cargo.toml" },
  #     cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" }
  #   })
  #
  #   vim.lsp.config("dartls", {
  #     filetypes = { "rust" },
  #     root_markers = { "Cargo.toml" },
  #     cmd = { "${pkgs.rust-analyzer}/bin/rust-analyzer" }
  #   })
  #
  #   vim.lsp.enable { "rust-analyzer", "dartls" }
  #   vim.diagnostic.config {
  #     virtual_lines = true,
  #   }
  # ''; 
}
