return {
  {
    "scalameta/nvim-metals",
    ft = { "scala", "sbt", "java" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      if vim.fn.executable("cs") ~= 1 and vim.fn.executable("coursier") ~= 1 then
        return
      end

      if vim.fn.executable("bloop") ~= 1 then
        return
      end

      local lsp = require("config.lsp")
      local metals = require("metals")
      local metals_config = metals.bare_config()

      metals_config.capabilities = lsp.capabilities()
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

        lsp.on_attach(client, bufnr)
        map("n", "<Leader>mi", "<Cmd>MetalsImportBuild<CR>", "Metals Import Build")
        map("n", "<Leader>md", "<Cmd>MetalsRunDoctor<CR>", "Metals Doctor")
        map("n", "<Leader>mr", "<Cmd>MetalsRestartBuild<CR>", "Metals Restart Build Server")
      end

      local group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })

      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "scala", "sbt", "java" },
        callback = function()
          metals.initialize_or_attach(metals_config)
        end,
      })
    end,
  },
}
