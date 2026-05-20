{ ... }:
let
  dirs = builtins.attrNames (
    builtins.filterAttrs (_: type: type == "directory") (builtins.readDir ./.)
  );
in
{
  imports = map (d: ./. + "/${d}") dirs;
}
