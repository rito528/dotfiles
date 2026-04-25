{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    jq
    direnv
    starship
    nodejs_24
    nixfmt
    doppler
    gh
    ripgrep
    shellcheck
    ghq
    fzf
    editorconfig-checker
    bubblewrap
    yazi
  ];
}
