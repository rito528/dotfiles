{ pkgs }:
let
  # renovate: datasource=github-releases depName=mizchi/actrun
  version = "0.21.2";
  src = pkgs.fetchurl {
    url = "https://github.com/mizchi/actrun/releases/download/v${version}/actrun-linux-x64.tar.gz";
    hash = "sha256-Y4YlCrhYmDFOjnyAJ1inA1c/UCg5waVmJLJMOc86R94=";
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
