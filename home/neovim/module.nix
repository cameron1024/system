{lib, pkgs, ...}: {
  imports = [
    ./blink-cmp.nix
    ./debug.nix
    ./diagnostics.nix
    ./editing.nix
    ./firenvim.nix
    ./formatting.nix
    ./git.nix
    ./lang
    ./lsp
    ./oil.nix
    ./overseer.nix
    ./settings
    ./snacks.nix
    ./test.nix
    ./theme.nix
    ./tmux-navigator.nix
    ./treesitter
    ./trouble.nix
  ];
  plugins."lz-n".enable = true;

  plugins.telescope.enable = lib.mkForce false;
  plugins.fzf-lua.enable = lib.mkForce false;
  # plugins.neotest.enable = lib.mkForce false;

  test.buildNixvim = false;
  test.runNvim = false;

  performance.byteCompileLua.enable = true;

  performance.byteCompileLua.configs = true;
  performance.byteCompileLua.initLua = true;
  performance.byteCompileLua.luaLib = true;
  performance.byteCompileLua.nvimRuntime = true;
  performance.byteCompileLua.plugins = true;

  performance.combinePlugins.enable = true;
}
