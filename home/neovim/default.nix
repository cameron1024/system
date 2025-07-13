{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.nixvim.homeManagerModules.default
    ./lang
    ./lsp
    ./treesitter

    # ./ai.nix
    ./blink-cmp.nix
    ./debug.nix
    ./distant.nix
    ./firenvim.nix
    ./formatting.nix
    ./git.nix
    # ./http
    ./oil.nix
    ./settings
    ./snacks.nix
    ./theme.nix
    ./test.nix
    ./trouble.nix
    ./tmux-navigator.nix
    ./editing.nix
    ./neorg.nix
    ./0x0.nix
  ];

  config = {
    programs.nixvim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      plugins."lz-n".enable = true;

      plugins.telescope.enable = lib.mkForce false;

      vimdiffAlias = true;

      performance.byteCompileLua.enable = true;

      performance.byteCompileLua.configs = true;
      performance.byteCompileLua.initLua = true;
      performance.byteCompileLua.luaLib = true;
      performance.byteCompileLua.nvimRuntime = true;
      performance.byteCompileLua.plugins = true;

      performance.combinePlugins.enable = true;
    };
  };
}
