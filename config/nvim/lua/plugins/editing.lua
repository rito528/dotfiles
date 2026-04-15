return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "tpope/vim-commentary",
    event = "VeryLazy",
    keys = {
      { "<C-/>", "<Cmd>Commentary<CR>", mode = "n", desc = "Toggle comment" },
      { "<C-_>", "<Cmd>Commentary<CR>", mode = "n", desc = "Toggle comment" },
      { "<C-/>", "<Plug>Commentary", mode = "x", desc = "Toggle comment" },
      { "<C-_>", "<Plug>Commentary", mode = "x", desc = "Toggle comment" },
    },
  },
  {
    "pocco81/auto-save.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
