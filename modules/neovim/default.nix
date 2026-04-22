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

  xdg.configFile."nvim/after/queries/rust/highlights.scm".source =
    ../../config/nvim/after/queries/rust/highlights.scm;

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    nixpkgs.useGlobalPackages = true;
    vimdiffAlias = true;
    imports = [
      ./base.nix
      ./plugins.nix
      ./lsp.nix
      ./scala.nix
    ];
  };
}
