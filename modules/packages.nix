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
    shellcheck
    ghq
    fzf
    editorconfig-checker
  ];
}
