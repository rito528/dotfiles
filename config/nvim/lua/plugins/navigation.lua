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
    opts = {
      view_options = {
        show_hidden = true,
      },
    },
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
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    keys = {
      { "<Leader>ld", "<Cmd>Glance definitions<CR>", desc = "Peek definitions" },
      { "<Leader>lr", "<Cmd>Glance references<CR>", desc = "Peek references" },
      { "<Leader>ly", "<Cmd>Glance type_definitions<CR>", desc = "Peek type definitions" },
      { "<Leader>li", "<Cmd>Glance implementations<CR>", desc = "Peek implementations" },
    },
    opts = function()
      local actions = require("glance").actions

      return {
        height = 18,
        preserve_win_context = true,
        detached = function(winid)
          return vim.api.nvim_win_get_width(winid) < 110
        end,
        preview_win_opts = {
          cursorline = true,
          number = true,
          wrap = true,
        },
        list = {
          position = "right",
          width = 0.33,
        },
        border = {
          enable = true,
        },
        mappings = {
          list = {
            ["j"] = actions.next,
            ["k"] = actions.previous,
            ["<Down>"] = actions.next,
            ["<Up>"] = actions.previous,
            ["<Tab>"] = actions.next_location,
            ["<S-Tab>"] = actions.previous_location,
            ["<C-u>"] = actions.preview_scroll_win(5),
            ["<C-d>"] = actions.preview_scroll_win(-5),
            ["v"] = actions.jump_vsplit,
            ["s"] = actions.jump_split,
            ["t"] = actions.jump_tab,
            ["<CR>"] = actions.jump,
            ["o"] = actions.jump,
            ["q"] = actions.close,
            ["Q"] = actions.close,
            ["<Esc>"] = actions.close,
          },
          preview = {
            ["Q"] = actions.close,
            ["<Tab>"] = actions.next_location,
            ["<S-Tab>"] = actions.previous_location,
          },
        },
        hooks = {
          before_open = function(results, open, jump)
            if #results == 1 then
              jump(results[1])
              return
            end

            open(results)
          end,
        },
      }
    end,
  },
}
