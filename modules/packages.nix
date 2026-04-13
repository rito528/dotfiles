{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    jq
    direnv
    starship
    neovim
    nixfmt
    doppler
    gh
    ripgrep
    claude-code
    github-copilot-cli
    gemini-cli
    codex
    shellcheck
    ghq
    fzf
    editorconfig-checker
    bubblewrap
    yazi
  ];
}
