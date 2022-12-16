{ pkgs, ... }:

let 
  treesitter = 
    (pkgs.vimPlugins.nvim-treesitter.withPlugins (
      plugins: with plugins; [
        tree-sitter-nix
        tree-sitter-rust
        tree-sitter-json
        tree-sitter-yaml
        tree-sitter-toml
        tree-sitter-haskell
        tree-sitter-dart
      ]
    ));

in

{
  programs.neovim.plugins = with pkgs.vimPlugins; [
    {
      plugin = treesitter;
      config = ''
      lua << EOF
      ${builtins.readFile ./config.lua}
      EOF
      '';
    }
  ];
}
