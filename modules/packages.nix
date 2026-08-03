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
  ];
  byProfile = {
    personal = with pkgs; [
      starship
      ripgrep
      ghq
      fzf
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
