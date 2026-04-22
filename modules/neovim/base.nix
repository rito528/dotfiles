{
  lib,
  ...
}:
let
  rustHighlightsQuery = builtins.readFile ../../config/nvim/after/queries/rust/highlights.scm;
in
{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  opts = {
    background = "";
    conceallevel = 2;
    cursorline = true;
    number = true;
    numberwidth = 4;
    relativenumber = true;
    signcolumn = "yes";
    statuscolumn = "%s%=%{v:lua.statuscolumn_numbers()}";
    termguicolors = true;
  };

  keymaps = [
    {
      key = "<C-/>";
      mode = "n";
      action = "<Cmd>Commentary<CR>";
      options.desc = "Toggle comment";
    }
    {
      key = "<C-_>";
      mode = "n";
      action = "<Cmd>Commentary<CR>";
      options.desc = "Toggle comment";
    }
    {
      key = "<C-/>";
      mode = "x";
      action = "<Plug>Commentary";
      options.desc = "Toggle comment";
    }
    {
      key = "<C-_>";
      mode = "x";
      action = "<Plug>Commentary";
      options.desc = "Toggle comment";
    }
    {
      key = "-";
      mode = "n";
      action = "<Cmd>Oil<CR>";
      options.desc = "Open parent directory";
    }
    {
      key = "<C-p>";
      mode = "n";
      action = "<Cmd>Telescope find_files<CR>";
      options.desc = "Find files";
    }
    {
      key = "<Leader>fb";
      mode = "n";
      action = "<Cmd>Telescope buffers<CR>";
      options.desc = "Buffers";
    }
    {
      key = "<Leader>fr";
      mode = "n";
      action = "<Cmd>Telescope oldfiles<CR>";
      options.desc = "Recent files";
    }
    {
      key = "<Leader>fg";
      mode = "n";
      action = "<Cmd>Telescope live_grep<CR>";
      options.desc = "Live grep";
    }
    {
      key = "<Leader>ld";
      mode = "n";
      action = "<Cmd>Glance definitions<CR>";
      options.desc = "Peek definitions";
    }
    {
      key = "<Leader>lr";
      mode = "n";
      action = "<Cmd>Glance references<CR>";
      options.desc = "Peek references";
    }
    {
      key = "<Leader>ly";
      mode = "n";
      action = "<Cmd>Glance type_definitions<CR>";
      options.desc = "Peek type definitions";
    }
    {
      key = "<Leader>li";
      mode = "n";
      action = "<Cmd>Glance implementations<CR>";
      options.desc = "Peek implementations";
    }
    {
      key = "<A-,>";
      mode = "n";
      action = "<Cmd>BufferPrevious<CR>";
      options.desc = "Previous buffer";
    }
    {
      key = "<A-.>";
      mode = "n";
      action = "<Cmd>BufferNext<CR>";
      options.desc = "Next buffer";
    }
    {
      key = "<A-<>";
      mode = "n";
      action = "<Cmd>BufferMovePrevious<CR>";
      options.desc = "Move buffer left";
    }
    {
      key = "<A->>";
      mode = "n";
      action = "<Cmd>BufferMoveNext<CR>";
      options.desc = "Move buffer right";
    }
    {
      key = "<A-c>";
      mode = "n";
      action = "<Cmd>BufferClose<CR>";
      options.desc = "Close buffer";
    }
    {
      key = "<A-p>";
      mode = "n";
      action = "<Cmd>BufferPin<CR>";
      options.desc = "Pin buffer";
    }
    {
      key = "<A-1>";
      mode = "n";
      action = "<Cmd>BufferGoto 1<CR>";
      options.desc = "Go to buffer 1";
    }
    {
      key = "<A-2>";
      mode = "n";
      action = "<Cmd>BufferGoto 2<CR>";
      options.desc = "Go to buffer 2";
    }
    {
      key = "<A-3>";
      mode = "n";
      action = "<Cmd>BufferGoto 3<CR>";
      options.desc = "Go to buffer 3";
    }
    {
      key = "<A-4>";
      mode = "n";
      action = "<Cmd>BufferGoto 4<CR>";
      options.desc = "Go to buffer 4";
    }
    {
      key = "<A-5>";
      mode = "n";
      action = "<Cmd>BufferGoto 5<CR>";
      options.desc = "Go to buffer 5";
    }
    {
      key = "<A-6>";
      mode = "n";
      action = "<Cmd>BufferGoto 6<CR>";
      options.desc = "Go to buffer 6";
    }
    {
      key = "<A-7>";
      mode = "n";
      action = "<Cmd>BufferGoto 7<CR>";
      options.desc = "Go to buffer 7";
    }
    {
      key = "<A-8>";
      mode = "n";
      action = "<Cmd>BufferGoto 8<CR>";
      options.desc = "Go to buffer 8";
    }
    {
      key = "<A-9>";
      mode = "n";
      action = "<Cmd>BufferGoto 9<CR>";
      options.desc = "Go to buffer 9";
    }
    {
      key = "<A-0>";
      mode = "n";
      action = "<Cmd>BufferLast<CR>";
      options.desc = "Go to last buffer";
    }
  ];

  colorschemes.kanagawa = {
    enable = true;
    settings = {
      theme = "wave";
      transparent = false;
      commentStyle.italic = true;
      keywordStyle.italic = true;
      overrides = lib.nixvim.mkRaw ''
        function(colors)
          local palette = colors.palette

          return {
            ["@attribute"] = { fg = palette.surimiOrange, italic = true },
            ["@function.macro"] = { fg = palette.surimiOrange, bold = true },
            ["@module"] = { fg = palette.springBlue },
            ["@constructor"] = { fg = palette.oniViolet, bold = true },
            ["@type"] = { fg = palette.waveAqua2, bold = true },
            ["@type.builtin"] = { fg = palette.waveAqua2, italic = true },
            ["@variable.member"] = { fg = palette.crystalBlue },

            ["@lsp.type.deriveHelper"] = { fg = palette.surimiOrange, italic = true, bold = true },
            ["@lsp.type.decorator"] = { fg = palette.surimiOrange, italic = true },
            ["@lsp.type.lifetime"] = { fg = palette.waveRed, italic = true },
            ["@lsp.type.namespace"] = { fg = palette.springBlue },
            ["@lsp.type.selfKeyword"] = { fg = palette.waveRed, italic = true },
            ["@lsp.type.selfTypeKeyword"] = { fg = palette.waveRed, italic = true },
          }
        end
      '';
    };
  };

  extraConfigLuaPre = ''
        function _G.statuscolumn_numbers()
          if vim.v.virtnum ~= 0 then
            return ""
          end

          local absolute = tostring(vim.v.lnum)
          local relative = tostring(vim.v.relnum)

          return string.format("%4s %4s ", absolute, relative)
        end

        for _, runtime in ipairs({
          vim.env.NVIM_TREESITTER_RUNTIME_GLOBAL,
          vim.env.NVIM_TREESITTER_RUNTIME_PROJECT,
        }) do
          if runtime and runtime ~= "" then
            vim.opt.rtp:append(runtime)
          end
        end

        vim.treesitter.query.set("rust", "highlights", [=[
    ${rustHighlightsQuery}
    ]=])
  '';

  autoCmd = [
    {
      event = "ColorScheme";
      group = "markdown_highlights";
      desc = "Apply custom markdown highlight groups";
      callback = lib.nixvim.mkRaw ''
        function()
          vim.api.nvim_set_hl(0, "markdownH1", { fg = "#7E9CD8", bold = true })
          vim.api.nvim_set_hl(0, "markdownH2", { fg = "#7FB4CA", bold = true })
          vim.api.nvim_set_hl(0, "markdownH3", { fg = "#938AA9", bold = true })
          vim.api.nvim_set_hl(0, "markdownCode", { fg = "#98BB6C", italic = true })
          vim.api.nvim_set_hl(0, "markdownCodeBlock", { fg = "#98BB6C" })
          vim.api.nvim_set_hl(0, "markdownLinkText", { fg = "#7E9CD8", underline = true })
          vim.api.nvim_set_hl(0, "markdownUrl", { fg = "#7FB4CA", underline = true })
          vim.api.nvim_set_hl(0, "markdownBold", { bold = true })
          vim.api.nvim_set_hl(0, "markdownItalic", { italic = true })
        end
      '';
    }
  ];
}
