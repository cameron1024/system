{pkgs, ...}: {
  home.packages = with pkgs; [alejandra typstyle];
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
        };
        formatters_by_ft = {
          "nix" = ["alejandra"];
          "typst" = ["typstyle"];
        };
      };
    };

    opts.formatexpr = "v:lua.require'conform'.formatexpr()";
  };
}
