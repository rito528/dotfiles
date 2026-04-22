{ ... }:
{
  plugins = {
    "copilot-vim" = {
      enable = true;
      settings.filetypes."*" = true;
    };

    lsp = {
      enable = true;
      onAttach = ''
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
      '';
      servers = {
        eslint = {
          enable = true;
          package = null;
          settings.eslint.autoFixOnSave = true;
        };
        jsonls = {
          enable = true;
          package = null;
        };
        rust_analyzer = {
          enable = true;
          installCargo = false;
          installRustc = false;
          package = null;
        };
        taplo = {
          enable = true;
          package = null;
        };
        ts_ls = {
          enable = true;
          package = null;
        };
      };
    };

    treesitter = {
      enable = true;
      nixGrammars = false;
      highlight.enable = true;
    };
  };
}
