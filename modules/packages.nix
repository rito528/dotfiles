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
    gemini-cli
    shellcheck
    ghq
    fzf
    editorconfig-checker
    bubblewrap
    yazi
  ];
}
