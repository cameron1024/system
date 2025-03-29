{pkgs, ...}: {
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.keys = [
        {
          __unkeyed-1 = "<MS-f>";
          __unkeyed-2.__raw = /* lua */ ''
            function() require 'conform'.format { async = true } end
          '';
        }
      ];
      settings = {
        formatters_by_ft = {
          "nix" = [ "${pkgs.alejandra}/bin/alejandra"];
        };
      };
    };

    opts.formatexpr = "v:lua.require'configm'.formatexpr()";
  };

}
