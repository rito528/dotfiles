{
  lib,
  username,
  homeDirectory,
  ...
}:
{
  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/ssh.nix
    ./modules/shell.nix
    ./modules/scripts
    ./modules/claude.nix
    ./modules/gitleaks.nix
    ./modules/npm
    ./modules/actrun.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;

  # 3件超または5日より古い generation を自動削除
  home.activation.collectGarbage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD nix-env --profile ~/.local/state/nix/profiles/home-manager --delete-generations +3 || true
    $DRY_RUN_CMD nix-collect-garbage --delete-older-than 5d || true
  '';
}
