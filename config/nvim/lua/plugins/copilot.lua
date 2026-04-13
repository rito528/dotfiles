return {
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "InsertEnter",
    init = function()
      vim.g.copilot_filetypes = {
        ["*"] = true,
      }
    end,
  },
}
