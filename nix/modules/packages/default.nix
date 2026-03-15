{ pkgs, ... }:
let
  allFiles = builtins.readDir ./.;
  nixFiles = builtins.filter (name: name != "default.nix" && builtins.match ".*\\.nix" name != null) (
    builtins.attrNames allFiles
  );
  packages = map (name: import (./${name}) { inherit pkgs; }) nixFiles;
in
{
  home.packages = packages;
}
