{
  programs.nixvim = {
    plugins.lsp.servers.ts_ls.enable = true;
    plugins.typescript-tools.enable = true;
  };
}
