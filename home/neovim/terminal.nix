{
  programs.nixvim = {
    plugins.toggleterm = {
      enable = true;
      # lazyLoad.enable = true;
      # lazyLoad.settings.keys = [
      #   {
      #     desc = "Toggle Terminal";
      #     __unkeyed-1 = "<leader>f";
      #     __unkeyed-2.__raw = /* lua */ ''
      #       function() Snacks.picker.grep() end
      #     '';
      #   }
      # ];
      settings.open_mapping = "<C-t>";
    };
  };
}
