{ pkgs, ... }:
let
  allFiles = builtins.readDir ./packages;
  nixFiles = builtins.filter (name: builtins.match ".*\\.nix" name != null) (
    builtins.attrNames allFiles
  );
  packages = map (name: import (./packages + "/${name}") { inherit pkgs; }) nixFiles;
in
{
  home.packages = packages;
}
