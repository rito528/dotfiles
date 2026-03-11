{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jq
    direnv
    starship
    nixfmt-rfc-style
    doppler
    gh
    ripgrep
    claude-code
  ];
}
