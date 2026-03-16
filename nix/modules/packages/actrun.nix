{ pkgs }:
let
  # renovate: datasource=github-releases depName=mizchi/actrun
  version = "0.12.0";
  src = pkgs.fetchurl {
    url = "https://github.com/mizchi/actrun/releases/download/v${version}/actrun-linux-x64.tar.gz";
    hash = "sha256-gSy64m4x0FLzNUZxl4lCege1Dp+78gFI4Y0GDot9T/s=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "actrun";
  inherit version src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    tar xzf $src -C $out/bin
    chmod +x $out/bin/actrun
  '';
}
