return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
    },
  },
  {
    "romgrk/barbar.nvim",
    version = "^1.0.0",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<A-,>", "<Cmd>BufferPrevious<CR>", desc = "Previous buffer" },
      { "<A-.>", "<Cmd>BufferNext<CR>", desc = "Next buffer" },
      { "<A-<>", "<Cmd>BufferMovePrevious<CR>", desc = "Move buffer left" },
      { "<A->>", "<Cmd>BufferMoveNext<CR>", desc = "Move buffer right" },
      { "<A-c>", "<Cmd>BufferClose<CR>", desc = "Close buffer" },
      { "<A-p>", "<Cmd>BufferPin<CR>", desc = "Pin buffer" },
      { "<A-1>", "<Cmd>BufferGoto 1<CR>", desc = "Go to buffer 1" },
      { "<A-2>", "<Cmd>BufferGoto 2<CR>", desc = "Go to buffer 2" },
      { "<A-3>", "<Cmd>BufferGoto 3<CR>", desc = "Go to buffer 3" },
      { "<A-4>", "<Cmd>BufferGoto 4<CR>", desc = "Go to buffer 4" },
      { "<A-5>", "<Cmd>BufferGoto 5<CR>", desc = "Go to buffer 5" },
      { "<A-6>", "<Cmd>BufferGoto 6<CR>", desc = "Go to buffer 6" },
      { "<A-7>", "<Cmd>BufferGoto 7<CR>", desc = "Go to buffer 7" },
      { "<A-8>", "<Cmd>BufferGoto 8<CR>", desc = "Go to buffer 8" },
      { "<A-9>", "<Cmd>BufferGoto 9<CR>", desc = "Go to buffer 9" },
      { "<A-0>", "<Cmd>BufferLast<CR>", desc = "Go to last buffer" },
    },
    init = function()
      vim.g.barbar_auto_setup = false
    end,
    opts = {},
  },
  {
    "preservim/vim-markdown",
    ft = { "markdown" },
    init = function()
      vim.g.vim_markdown_conceal = 0
      vim.g.vim_markdown_conceal_code_blocks = 0
      vim.g.vim_markdown_frontmatter = 1
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_strikethrough = 1
    end,
  },
}
