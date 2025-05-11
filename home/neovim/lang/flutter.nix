{
  programs.nixvim = {
    plugins.lsp.servers.dartls = {
      enable = true;
      settings.showTodos = false;
    };

    plugins.flutter-tools.enable = true;
  };
}
