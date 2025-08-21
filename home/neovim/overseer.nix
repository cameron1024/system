{
  plugins.overseer = {
    enable = true;
    lazyLoad.settings.before.__raw = ''
    function()
      require "lz.n".trigger_load ""
    end
    '';
    lazyLoad.settings.keys = [
      {
        __unkeyed-1 = "<leader>o";
        __unkeyed-2 = "<cmd>OverseerToggle<cr>";
      }
      {
        __unkeyed-1 = "<leader>l";
        __unkeyed-2.__raw = ''
        function()
          require "lz.n".trigger_load "snacks.nvim"
          vim.cmd "OverseerRun"
        end
        '';
      }
    ];
  };
}
