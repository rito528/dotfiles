{
  lib,
  username,
  homeDirectory,
  profile,
  ...
}:
let
  commonImports = [
    ./modules/packages.nix
    ./modules/llm-agents.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/ssh.nix
    ./modules/neovim
    ./modules/shell.nix
    ./modules/yazi.nix
    ./modules/scripts
    ./modules/agents.nix
    ./modules/claude.nix
    ./modules/gitleaks.nix
    ./modules/npm
    ./modules/git-wt.nix
  ];
  profileImports = {
    personal = [
      ./modules/grafana-mcp.nix
      ./modules/codex.nix
      ./modules/takt.nix
      ./modules/actrun.nix
    ];
    work = [ ];
  };
in
{
  imports = commonImports ++ profileImports.${profile};

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
