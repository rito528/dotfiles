{ lib, pkgs, ... }:
{
  extraPlugins = [
    pkgs.vimPlugins."friendly-snippets"
    pkgs.vimPlugins."nvim-metals"
    pkgs.vimPlugins."vim-commentary"
    pkgs.vimPlugins."vim-markdown"
  ];

  plugins = {
    "auto-save".enable = true;
    barbar = {
      enable = true;
      settings = { };
    };
    "blink-cmp" = {
      enable = true;
      settings = {
        appearance.nerd_font_variant = "mono";
        cmdline = {
          completion.menu.auto_show = true;
          keymap.preset = "inherit";
        };
        completion.documentation.auto_show = false;
        fuzzy.implementation = "lua";
        keymap.preset = "super-tab";
        sources.default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];
      };
    };
    glance = {
      enable = true;
      settings = {
        border.enable = true;
        detached = lib.nixvim.mkRaw ''
          function(winid)
            return vim.api.nvim_win_get_width(winid) < 110
          end
        '';
        height = 18;
        hooks.before_open = lib.nixvim.mkRaw ''
          function(results, open, jump)
            if #results == 1 then
              jump(results[1])
              return
            end

            open(results)
          end
        '';
        list = {
          position = "right";
          width = 0.33;
        };
        mappings = {
          list = {
            "<CR>" = lib.nixvim.mkRaw "require('glance').actions.jump";
            "<C-d>" = lib.nixvim.mkRaw "require('glance').actions.preview_scroll_win(-5)";
            "<C-u>" = lib.nixvim.mkRaw "require('glance').actions.preview_scroll_win(5)";
            "<Down>" = lib.nixvim.mkRaw "require('glance').actions.next";
            "<Esc>" = lib.nixvim.mkRaw "require('glance').actions.close";
            "<S-Tab>" = lib.nixvim.mkRaw "require('glance').actions.previous_location";
            "<Tab>" = lib.nixvim.mkRaw "require('glance').actions.next_location";
            "<Up>" = lib.nixvim.mkRaw "require('glance').actions.previous";
            "Q" = lib.nixvim.mkRaw "require('glance').actions.close";
            "j" = lib.nixvim.mkRaw "require('glance').actions.next";
            "k" = lib.nixvim.mkRaw "require('glance').actions.previous";
            "o" = lib.nixvim.mkRaw "require('glance').actions.jump";
            "q" = lib.nixvim.mkRaw "require('glance').actions.close";
            "s" = lib.nixvim.mkRaw "require('glance').actions.jump_split";
            "t" = lib.nixvim.mkRaw "require('glance').actions.jump_tab";
            "v" = lib.nixvim.mkRaw "require('glance').actions.jump_vsplit";
          };
          preview = {
            "<S-Tab>" = lib.nixvim.mkRaw "require('glance').actions.previous_location";
            "<Tab>" = lib.nixvim.mkRaw "require('glance').actions.next_location";
            "Q" = lib.nixvim.mkRaw "require('glance').actions.close";
          };
        };
        preserve_win_context = true;
        preview_win_opts = {
          cursorline = true;
          number = true;
          wrap = true;
        };
      };
    };
    lualine = {
      enable = true;
      settings.options = {
        globalstatus = true;
        theme = "auto";
      };
    };
    "nvim-autopairs".enable = true;
    oil = {
      enable = true;
      settings.view_options.show_hidden = true;
    };
    telescope = {
      enable = true;
      settings = {
        defaults = {
          layout_config = {
            height = 0.9;
            preview_width = 0.6;
            prompt_position = "top";
            width = 0.95;
          };
          layout_strategy = "horizontal";
          path_display = [ "smart" ];
          sorting_strategy = "ascending";
          wrap_results = true;
        };
        pickers = {
          find_files.hidden = true;
          live_grep.only_sort_text = true;
        };
      };
    };
    web-devicons.enable = true;
  };

  extraConfigLuaPre = ''
    vim.g.vim_markdown_conceal = 0
    vim.g.vim_markdown_conceal_code_blocks = 0
    vim.g.vim_markdown_frontmatter = 1
    vim.g.vim_markdown_folding_disabled = 1
    vim.g.vim_markdown_strikethrough = 1
  '';
}
