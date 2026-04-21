return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "lua",
          "rust",
          "toml",
          "typescript",
          "javascript",
          "json",
          "markdown",
          "markdown_inline",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
