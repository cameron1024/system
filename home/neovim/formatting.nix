{pkgs, ...}: {
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.keys = [
        {
          __unkeyed-1 = "<MS-f>";
          __unkeyed-2.__raw = ''
            function() require 'conform'.format { async = true } end
          '';
        }
      ];
      settings = {
        default_format_opts.lsp_format = "fallback";
        formatters = {
          typstyle = {
            command = "${pkgs.typstyle}/bin/typstyle";
            args = ["-i" "-t" "2" "$FILENAME"];
            stdin = false;
          };
          sql-formatter = {
            command = "${pkgs.sql-formatter}/bin/sql-formatter";
            args = ["--fix" "$FILENAME"];
            stdin = false;
          };
          injected = {
            ignore_errors = false;
          };
        };
        formatters_by_ft = {
          "markdown" = ["injected"];
          "rust" = [ "rustfmt" "injected" ];
          "nix" = ["alejandra" "injected"];
          "typst" = ["typstyle" "injected"];
          "sh" = ["shfmt"];
          "sql" = ["sql-formatter"];
          "json" = ["jq"];
        };
      };
    };

    opts.formatexpr = "v:lua.require'conform'.formatexpr()";
  };
}
