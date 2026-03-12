{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq
    direnv
    starship
    nixfmt
    doppler
    gh
    ripgrep
    claude-code
  ];
}
