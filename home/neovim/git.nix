{
  programs.nixvim = {
    plugins.diffview.enable = true;

    plugins.gitsigns = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.events = ["BufReadPost"];

      settings = {
        current_line_blame = true;
        current_line_blame_opts = {
          virt_text = true;
          virt_text_pos = "eol";
        };
      };
    };

    plugins.octo = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.cmd = "Octo";
    };
  };
}
