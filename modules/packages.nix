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
    bubblewrap
    socat
    yazi
    python3
  ];
}
