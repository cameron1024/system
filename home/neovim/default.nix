{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.nixvim.homeManagerModules.default
    ./lang
    ./lsp
    # ./ai.nix
    ./blink-cmp.nix
    ./debug.nix
    ./firenvim.nix
    ./formatting.nix
    ./git.nix
    # ./http
    ./oil.nix
    ./settings
    ./snacks.nix
    ./theme.nix
    ./treesitter.nix
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

      vimdiffAlias = true;

      performance.byteCompileLua.enable = true;
      performance.byteCompileLua.nvimRuntime = true;
      performance.byteCompileLua.plugins = true;

      performance.combinePlugins.enable = true;
      performance.combinePlugins.standalonePlugins = [
        "firenvim"
      ];
    };
  };
}
