vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.numberwidth = 4
vim.opt.conceallevel = 2

function _G.statuscolumn_numbers()
  if vim.v.virtnum ~= 0 then
    return ""
  end

  local absolute = tostring(vim.v.lnum)
  local relative = tostring(vim.v.relnum)

  return string.format("%4s %4s ", absolute, relative)
end

vim.opt.statuscolumn = "%s%=%{v:lua.statuscolumn_numbers()}"

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

vim.cmd.colorscheme("tokyonight")

local markdown_highlights = vim.api.nvim_create_augroup("markdown_highlights", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = markdown_highlights,
  callback = function()
    vim.api.nvim_set_hl(0, "markdownH1", { fg = "#7aa2f7", bold = true })
    vim.api.nvim_set_hl(0, "markdownH2", { fg = "#7dcfff", bold = true })
    vim.api.nvim_set_hl(0, "markdownH3", { fg = "#89ddff", bold = true })
    vim.api.nvim_set_hl(0, "markdownCode", { fg = "#73daca", italic = true })
    vim.api.nvim_set_hl(0, "markdownCodeBlock", { fg = "#73daca" })
    vim.api.nvim_set_hl(0, "markdownLinkText", { fg = "#7aa2f7", underline = true })
    vim.api.nvim_set_hl(0, "markdownUrl", { fg = "#2ac3de", underline = true })
    vim.api.nvim_set_hl(0, "markdownBold", { bold = true })
    vim.api.nvim_set_hl(0, "markdownItalic", { italic = true })
  end,
})

vim.api.nvim_exec_autocmds("ColorScheme", { group = markdown_highlights })
