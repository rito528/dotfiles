{
  username,
  homeDirectory,
  ...
}:
{
  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/shell.nix
    ./modules/claude.nix
    ./modules/secretlint.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
