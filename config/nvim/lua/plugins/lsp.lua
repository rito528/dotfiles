return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lsp = require("config.lsp")
      local base_config = {
        capabilities = lsp.capabilities(),
        on_attach = lsp.on_attach,
      }

      vim.lsp.config("ts_ls", base_config)
      vim.lsp.enable("ts_ls")

      vim.lsp.config("eslint", {
        capabilities = base_config.capabilities,
        on_attach = base_config.on_attach,
        settings = {
          eslint = {
            autoFixOnSave = true,
          },
        },
      })
      vim.lsp.enable("eslint")

      vim.lsp.config("jsonls", base_config)
      vim.lsp.enable("jsonls")

      vim.lsp.config("rust_analyzer", base_config)
      vim.lsp.enable("rust_analyzer")

      vim.lsp.config("taplo", base_config)
      vim.lsp.enable("taplo")
    end,
  },
}
