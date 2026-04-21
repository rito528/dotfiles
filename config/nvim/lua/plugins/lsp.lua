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

      vim.lsp.config("rust_analyzer", {})
      vim.lsp.enable("rust_analyzer")

      vim.lsp.config("taplo", {})
      vim.lsp.enable("taplo")
    end,
  },
}
