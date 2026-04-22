return {
  {
    "saghen/blink.cmp",
    lazy = false,
    version = "1.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        preset = "super-tab",
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      completion = {
        documentation = {
          auto_show = false,
        },
      },
      cmdline = {
        keymap = {
          preset = "inherit",
        },
        completion = {
          menu = {
            auto_show = true,
          },
        },
      },
      fuzzy = {
        implementation = "lua",
      },
    },
  },
}
