{pkgs, ...}: {
  home.shellAliases = {
    "e" = "nvim";
    "ed" = "nvim +DiffviewOpen";
    "nv" = "neovide --fork";
  };

  home.sessionVariables = {
    "EDITOR" = "nvim";
    "MANPAGER" = "nvim +Man!";
  };

  xdg.configFile."kdlfmt/kdlfmt.kdl".text = ''
    indent_size 2
    use_tabs #false
  '';

  home.packages = with pkgs; [
    typst
    neovide

    alejandra
    typstyle
    shfmt
    sql-formatter
    kdlfmt

    imagemagick
    mermaid-cli
    ghostscript
  ];
}
