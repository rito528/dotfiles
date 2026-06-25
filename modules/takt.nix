{ pkgs, takt, ... }:
{
  home.packages = [ takt.packages.${pkgs.stdenv.hostPlatform.system}.default ];
}
