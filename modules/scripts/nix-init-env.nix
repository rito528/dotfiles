{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "nix-init-env";
      runtimeInputs = [
        pkgs.nix
        pkgs.jq
        pkgs.coreutils
      ];
      text = builtins.readFile ./nix-init-env.sh;
    })
  ];
}
