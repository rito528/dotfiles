vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.conceallevel = 2

vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

local uv = vim.uv or vim.loop
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lazy_init = lazypath .. "/lua/lazy/init.lua"

if not uv.fs_stat(lazy_init) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

if not uv.fs_stat(lazy_init) then
  vim.schedule(function()
    vim.notify("lazy.nvim の取得に失敗しました。:checkhealth とネットワーク状態を確認してください。", vim.log.levels.ERROR)
  end)
  return
end

vim.opt.rtp:prepend(lazypath)
require("lazy").setup("plugins")

vim.cmd.colorscheme("gruvbox")

local markdown_highlights = vim.api.nvim_create_augroup("markdown_highlights", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = markdown_highlights,
  callback = function()
    vim.api.nvim_set_hl(0, "markdownH1", { fg = "#fb4934", bold = true })
    vim.api.nvim_set_hl(0, "markdownH2", { fg = "#fe8019", bold = true })
    vim.api.nvim_set_hl(0, "markdownH3", { fg = "#fabd2f", bold = true })
    vim.api.nvim_set_hl(0, "markdownCode", { fg = "#b8bb26", italic = true })
    vim.api.nvim_set_hl(0, "markdownCodeBlock", { fg = "#b8bb26" })
    vim.api.nvim_set_hl(0, "markdownLinkText", { fg = "#83a598", underline = true })
    vim.api.nvim_set_hl(0, "markdownUrl", { fg = "#8ec07c", underline = true })
    vim.api.nvim_set_hl(0, "markdownBold", { bold = true })
    vim.api.nvim_set_hl(0, "markdownItalic", { italic = true })
  end,
})

vim.api.nvim_exec_autocmds("ColorScheme", { group = markdown_highlights })
