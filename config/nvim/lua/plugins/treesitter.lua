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
          "scala",
          "hcl",
          "yaml",
          "sql",
        },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
