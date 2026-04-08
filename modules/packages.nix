{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    jq
    direnv
    starship
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
  ];
}
