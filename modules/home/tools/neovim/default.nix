{
  pkgs,
  isDarwin,
  ...
}: let
  lldbAdapter = pkgs.vscode-extensions.vadimcn.vscode-lldb.adapter;

  linuxPackages = with pkgs; [
    neovide
  ];

  macosPackages = [];
in {
  home.packages = with pkgs;
    [
      neovim-nightly

      nil # nix lsp
      lua-language-server
      # lldb
      # lldbAdapter

      taplo
      yamlfmt
    ]
    ++ (
      if isDarwin
      then macosPackages
      else linuxPackages
    );

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };

  # home.sessionVariables = {
  #   LIBLLDB_PATH = "${lldbAdapter}/lib/libcodelldb.so";
  #   CODELLDB_PATH = "${lldbAdapter}/bin/codelldb";
  # };
}
