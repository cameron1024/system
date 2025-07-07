{
  programs.nixvim = {
    plugins.firenvim.enable = true;
    globals.firenvim_config = {
      localSettings = {
        ".*" = {
          takeover = "never";
          priority = 0;
        };
      };
    };
    performance.combinePlugins.standalonePlugins = [
      "firenvim"
    ];
  };
}
