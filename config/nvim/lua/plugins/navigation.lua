return {
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "-", "<Cmd>Oil<CR>", desc = "Open parent directory" },
    },
    opts = {},
  },
  {
    "nvim-telescope/telescope.nvim",
    version = "*",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<C-p>", "<Cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<Leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<Leader>fr", "<Cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<Leader>fg", "<Cmd>Telescope live_grep<CR>", desc = "Live grep" },
    },
    opts = {},
  },
}
