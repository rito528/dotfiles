{
  pkgs,
  profile,
  ...
}:
let
  common = with pkgs; [
    git
    jq
    nixfmt
    gh
    shellcheck
    nodejs_24
    starship
    ripgrep
    ghq
    fzf
  ];
  byProfile = {
    personal = with pkgs; [
      doppler
      actionlint
      editorconfig-checker
      markdown-link-check
      bubblewrap
      socat
      yazi
      python3
      mdbook
    ];
    work = [ ];
  };
in
{
  home.packages = common ++ byProfile.${profile};
}
