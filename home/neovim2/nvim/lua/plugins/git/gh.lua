return {
  "ldelossa/gh.nvim",
  lazy = true,
  dependencies = {
    { "ldelossa/litee.nvim", lazy = true, config = function() require 'litee.lib'.setup() end, },
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require 'litee.gh'.setup {
      keymaps = {
        actions = "<C-q>",
      }
    }
  end,
  cmd = {
    "GHOpenPR",
    "GHSearchPRs",
    "GHStartReview",
    "GHDeleteReview",
    "GHSubmitReview",
    "GHRequestedReview",
    "GHReviewed",
    "GHApproveReview",
  },
}
