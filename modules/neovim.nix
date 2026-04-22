{ pkgs, ... }:
let
  commonTreesitterRuntime = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    plugins: with plugins; [
      json
      lua
      markdown
      markdown_inline
      toml
      yaml
    ]
  );
in
{
  home.sessionVariables.NVIM_TREESITTER_RUNTIME_GLOBAL = "${commonTreesitterRuntime}";

  xdg.configFile."nvim".source = ../config/nvim;
}
