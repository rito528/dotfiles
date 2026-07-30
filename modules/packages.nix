{
  pkgs,
  profile,
  ...
}:
let
  common = with pkgs; [
    git
    jq
    starship
    nixfmt
    gh
    ripgrep
    shellcheck
    ghq
    fzf
    nodejs_24
  ];
  byProfile = {
    personal = with pkgs; [
      direnv
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
