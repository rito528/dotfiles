{ ... }:
let
  entries = builtins.readDir ./.;
  dirs = builtins.filter (name: entries.${name} == "directory") (builtins.attrNames entries);
in
{
  imports = map (d: ./. + "/${d}") dirs;
}
