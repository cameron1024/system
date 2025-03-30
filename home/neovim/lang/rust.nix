{pkgs, ... }: {
  home.packages = with pkgs; [lldb];

  programs.nixvim = {
    plugins.rustaceanvim = {
      enable = true;
      lazyLoad.enable = true;
      lazyLoad.settings.ft = "rust";
      lazyLoad.settings.before.__raw = ''
        require 'lz.n'.trigger_load 'dap'
      '';

      settings.dap.autoload_configurations = true;
      settings.server.load_vscode_settings = true;
      settings.tools.test_executor = "neotest";
      settings.tools.enable_nextest = true;
      settings.tools.enable_clippy = true;
    };
  };
}
