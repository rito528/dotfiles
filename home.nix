{
  lib,
  username,
  homeDirectory,
  profile,
  isDarwin,
  ...
}:
let
  commonImports = [
    ./modules/packages.nix
    ./modules/llm-agents.nix
    ./modules/git.nix
    ./modules/neovim
    ./modules/shell.nix
    ./modules/scripts
    ./modules/agents.nix
    ./modules/claude.nix
  ];
  profileImports = {
    personal = [
      ./modules/gpg.nix
      ./modules/ssh.nix
      ./modules/grafana-mcp.nix
      ./modules/codex.nix
      ./modules/takt.nix
      ./modules/actrun.nix
      ./modules/gitleaks.nix
      ./modules/git-wt.nix
      ./modules/yazi.nix
      ./modules/npm
    ];
    work = [ ];
  };
  platformImports = {
    darwin = [ ./modules/karabiner.nix ];
    linux = [ ];
  };
  # isDarwin は pkgs.stdenv.isDarwin ではなく flake.nix が system 文字列から計算して
  # special arg として渡す（imports 評価中に pkgs を参照すると無限再帰になるため）。
  platform = if isDarwin then "darwin" else "linux";
in
{
  imports = commonImports ++ profileImports.${profile} ++ platformImports.${platform};

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
