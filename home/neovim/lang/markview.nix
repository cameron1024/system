{
  programs.nixvim.plugins.markview = {
    enable = true;
    lazyLoad.enable = true;
    lazyLoad.settings.filetypes = ["markdown" "typst"];
    settings = {
      preview.modes = ["n" "x"];
      preview.hybrid_modes = ["i" "r"];
    };
  };
}
