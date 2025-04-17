{
  programs.nixvim = {
    plugins.kulala = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.event = "BufEnter";

      settings.global_keymaps = true;
      settings.kulala_keymaps = true;
    };
  };
}
