{pkgs, inputs, ...}: {
  imports = [
    inputs.nixvim.homeManagerModules.default
    ./lang
    ./blink-cmp.nix
    ./firenvim.nix
    ./formatting.nix
    ./git.nix
    ./lsp.nix
    ./oil.nix
    ./settings
    ./snacks.nix
    ./treesitter.nix
    ./theme.nix
    ./tmux-navigator.nix
    ./editing.nix
  ];

  config = {
    home.shellAliases = {
      "e" = "nvim";
      "ed" = "nvim +DiffviewOpen";
    };

    home.sessionVariables = {
      "EDITOR" = "nvim";
      "MANPAGER" = "nvim +Man!";
    };

    programs.nixvim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      plugins."lz-n".enable = true;

      vimdiffAlias = true;
      performance.byteCompileLua.enable = true;
      performance.combinePlugins.enable = true;
      performance.combinePlugins.standalonePlugins = ["firenvim"];

    };
  };
}
