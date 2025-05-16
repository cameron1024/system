{
  programs.nixvim = {
    plugins.lsp.servers.dartls = {
      settings.showTodos = false;
    };

    plugins.flutter-tools.enable = true;
  };
}
