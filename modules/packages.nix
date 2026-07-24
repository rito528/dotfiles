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
    actionlint
    ghq
    fzf
    editorconfig-checker
    markdown-link-check
    bubblewrap
    socat
    yazi
    python3
    mdbook
  ];
}
