{
  programs.nixvim.plugins.oil = {
    enable = true;

    lazyLoad = {
      enable = true;
      settings.keys = [
        {
          __unkeyed-1 = "-";
          __unkeyed-2.__raw =
            /*
            lua
            */
            ''
              function() require 'oil'.open() end
            '';
          desc = "Oil";
        }
      ];
    };

    settings = {
      default_file_explorer = true;
      columns = ["icon" "size"];
      keymaps = {
        "<C-p>" = "actions.parent";
        "K" = "actions.preview";
        "-" = "actions.close";
        "<C-t>" = false;
        "<C-v>" = false;
        "<C-x>" = false;
        "<C-h>" = false;
        "<C-j>" = false;
        "<C-k>" = false;
        "<C-l>" = false;
        "<leader>p" = false;
      };
    };
  };
}
