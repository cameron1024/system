{pkgs, ...}: {
  # vim.g.* = ...;
  globals = {
    mapleader = " ";
    maplocalleader = "  ";
  };

  # vim.opt.* = ...;
  opts = {
    timeoutlen = 600;
    cmdheight = 0;

    number = true;
    relativenumber = true;
    signcolumn = "yes:2";
    cursorline = true;

    splitright = true;
    splitbelow = true;

    conceallevel = 2;

    clipboard = "unnamedplus";

    shell = "fish";

    autowriteall = true;
    backup = false;
    swapfile = false;
    undodir = "/tmp/.nvimdid";
    undofile = true;

    hlsearch = true;
    incsearch = true;
    showmode = false;
    ignorecase = true;
    smartcase = true;

    expandtab = true;
    shiftround = true;
    shiftwidth = 2;
    tabstop = 2;
    # textwidth = 0;
    # textwidth.__raw = "vim.g.started_by_firenvim and 0 or 80";

    spell = true;

    guifont =
      if pkgs.stdenv.isLinux
      then "FiraCode Nerd Font:12"
      else "Fira Code:12";
  };
}
