{pkgs, ...}: {
  programs.nixvim.userCommands = {
    "Wrap" = {
      command.__raw = /* lua */ "function() vim.wo.wrap = not vim.wo.wrap end";
    };
  };
}
