{ lib, ... }:
{
  autoCmd = [
    {
      event = "FileType";
      pattern = [
        "scala"
        "sbt"
        "java"
      ];
      group = "nvim-metals";
      desc = "Attach nvim-metals when Scala tooling is available";
      callback = lib.nixvim.mkRaw ''
        function()
          if vim.fn.executable("cs") ~= 1 and vim.fn.executable("coursier") ~= 1 then
            return
          end

          if vim.fn.executable("bloop") ~= 1 then
            return
          end

          local metals = require("metals")
          local metals_config = metals.bare_config()

          metals_config.capabilities = require("blink.cmp").get_lsp_capabilities()
          metals_config.init_options = vim.tbl_deep_extend("force", metals_config.init_options or {}, {
            statusBarProvider = "on",
          })
          metals_config.settings = {
            showImplicitArguments = true,
            showInferredType = true,
          }
          metals_config.on_attach = function(client, bufnr)
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

            map("n", "<Leader>mi", "<Cmd>MetalsImportBuild<CR>", "Metals Import Build")
            map("n", "<Leader>md", "<Cmd>MetalsRunDoctor<CR>", "Metals Doctor")
            map("n", "<Leader>mr", "<Cmd>MetalsRestartBuild<CR>", "Metals Restart Build Server")
          end

          metals.initialize_or_attach(metals_config)
        end
      '';
    }
  ];
}
