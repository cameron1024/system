{
  diagnostic.settings = {
    virtual_lines = false;
    virtual_text = false;
    # signs = true;
    signs = {
      text.__raw = ''
        function()
          return {
            vim.diagnostic.severity.ERROR = "",
            vim.diagnostic.severity.WARN = "",
            vim.diagnostic.severity.INFO = "",
            vim.diagnostic.severity.HINT = "",
          }
        end
      '';
    };
  };

  plugins.tiny-inline-diagnostic.enable = true;
  plugins.tiny-inline-diagnostic.settings = {
    preset = "powerline";
  };

  keymaps = [
    {
      key = "<leader>d";
      action.__raw = "function() require 'tiny-inline-diagnostic'.toggle() end";
    }
  ];
}
