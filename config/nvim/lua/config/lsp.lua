local M = {}

function M.capabilities()
  local base = vim.lsp.protocol.make_client_capabilities()
  local ok, blink = pcall(require, "blink.cmp")

  if not ok then
    return base
  end

  return blink.get_lsp_capabilities(base)
end

function M.on_attach(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, {
      buffer = bufnr,
      silent = true,
      desc = desc,
    })
  end

  map("n", "K", vim.lsp.buf.hover, "LSP Hover")
  map("n", "gd", vim.lsp.buf.definition, "LSP Definition")
  map("n", "gD", vim.lsp.buf.declaration, "LSP Declaration")
  map("n", "gi", vim.lsp.buf.implementation, "LSP Implementation")
  map("n", "gr", vim.lsp.buf.references, "LSP References")
  map("n", "<Leader>rn", vim.lsp.buf.rename, "LSP Rename")
  map({ "n", "v" }, "<Leader>ca", vim.lsp.buf.code_action, "LSP Code Action")
  map("n", "<Leader>lf", vim.diagnostic.open_float, "Line Diagnostics")
  map("n", "[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
  map("n", "]d", vim.diagnostic.goto_next, "Next Diagnostic")
end

return M
