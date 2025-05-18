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
        default_format_opts.lsp_format = "fallback";
        # formatters = {
        #   ronfmt = {
        #     command = "ronfmt";
        #     args = ["-t" "2" "$FILENAME"];
        #     stdin = false;
        #   };
        # };
        formatters_by_ft = {
          "nix" = ["alejandra"];
          # "ron" = ["ronfmt"];
        };
      };
    };

    opts.formatexpr = "v:lua.require'conform'.formatexpr()";
  };
}
