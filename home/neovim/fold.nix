{
  plugins.origami = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.event = "BufReadPre";
    lazyLoad.settings.before.__raw = ''
      function() require 'lz.n'.trigger_load 'nvim-treesitter' end
    '';
    lazyLoad.settings.keys = [
      # {
      #   __unkeyed-1 = "zR";
      #   __unkeyed-2.__raw = ''
      #     function() require 'ufo'.openAllFolds() end
      #   '';
      # }
      # {
      #   __unkeyed-1 = "zM";
      #   __unkeyed-2.__raw = ''
      #     function() require 'ufo'.closeAllFolds() end
      #   '';
      # }
      {
        __unkeyed-1 = "<leader><BS>";
        __unkeyed-2 = "za";
      }
    ];
  };
}
