{ ... }:
{
  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/shell.nix
    ./modules/vscode.nix
    ./modules/claude.nix
    ./modules/secretlint.nix
  ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
