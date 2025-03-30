{pkgs, ...}: {
  home.packages = with pkgs; [alejandra];
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.keys = [
        {
          __unkeyed-1 = "<MS-f>";
          __unkeyed-2.__raw =
            /*
            lua
            */
            ''
              function() require 'conform'.format { async = true } end
            '';
        }
      ];
      settings = {
        formatters_by_ft = {
          "nix" = ["alejandra"];
        };
        default_format_opts.lsp_format = "fallback";
      };
    };

    opts.formatexpr = "v:lua.require'conform'.formatexpr()";
  };
}
