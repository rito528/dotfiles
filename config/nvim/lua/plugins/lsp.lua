return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.lsp.config("ts_ls", {})
      vim.lsp.enable("ts_ls")

      vim.lsp.config("eslint", {
        settings = {
          eslint = {
            autoFixOnSave = true,
          },
        },
      })
      vim.lsp.enable("eslint")

      vim.lsp.config("jsonls", {})
      vim.lsp.enable("jsonls")
    end,
  },
}
