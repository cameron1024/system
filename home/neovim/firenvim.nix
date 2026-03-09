{
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

  plugins.auto-save.settings.condition.__raw = ''
    function(buf)
      return not vim.g.started_by_firenvim
    end
  '';
}
