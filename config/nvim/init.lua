vim.opt.number = true
vim.opt.relativenumber = true

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
