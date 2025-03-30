let
  mode = ["n" "i" "x" "o" "v" "t"];
in {
  programs.nixvim.plugins.tmux-navigator = {
    enable = true;
    settings.no_mappings = 1;
  };

  programs.nixvim.keymaps = [
    {
      key = "<C-h>";
      action = "<cmd>TmuxNavigateLeft<cr>";
      inherit mode;
    }
    {
      key = "<C-j>";
      action = "<cmd>TmuxNavigateDown<cr>";
      inherit mode;
    }
    {
      key = "<C-k>";
      action = "<cmd>TmuxNavigateUp<cr>";
      inherit mode;
    }
    {
      key = "<C-l>";
      action = "<cmd>TmuxNavigateRight<cr>";
      inherit mode;
    }
  ];
}
