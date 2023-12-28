return {
  'simrat39/rust-tools.nvim',
  lazy = false,
  config = function()
    -- local codelldb_path = vim.env.CODELLDB_PATH;
    -- local liblldb_path = vim.env.LIBLLDB_PATH;
    -- local adapter = require 'rust-tools.dap'.get_codelldb_adapter(codelldb_path, liblldb_path)
    --
    require 'rust-tools'.setup {
      dap = {
        -- adapter = adapter,
      },
    }
  end
}
