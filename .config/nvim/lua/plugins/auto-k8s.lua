return {
  {
    "aaronshifman/auto-k8s.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    config = function()
      require("auto-k8s").setup({
        -- Optional configuration here
      })
    end,
  },
}
