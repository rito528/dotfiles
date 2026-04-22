local enabled_languages = {
  hcl = true,
  javascript = true,
  json = true,
  lua = true,
  markdown = true,
  markdown_inline = true,
  rust = true,
  scala = true,
  sql = true,
  toml = true,
  typescript = true,
  yaml = true,
}

local function start_treesitter(bufnr)
  local filetype = vim.bo[bufnr].filetype
  local lang = vim.treesitter.language.get_lang(filetype) or filetype

  if not enabled_languages[lang] then
    return
  end

  if not pcall(vim.treesitter.language.add, lang) then
    return
  end

  pcall(vim.treesitter.start, bufnr, lang)
end

local group = vim.api.nvim_create_augroup("builtin_treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    start_treesitter(args.buf)
  end,
})

for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(bufnr) then
    start_treesitter(bufnr)
  end
end
