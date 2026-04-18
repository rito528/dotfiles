return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      if vim.fn.executable("typescript-language-server") == 1 then
        vim.lsp.config("ts_ls", {})
        vim.lsp.enable("ts_ls")
      end

      if vim.fn.executable("vscode-eslint-language-server") == 1 then
        vim.lsp.config("eslint", {
          settings = {
            eslint = {
              autoFixOnSave = true,
            },
          },
        })
        vim.lsp.enable("eslint")
      end

      if vim.fn.executable("vscode-json-language-server") == 1 then
        vim.lsp.config("jsonls", {})
        vim.lsp.enable("jsonls")
      end
    end,
  },
}
