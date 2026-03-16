{ pkgs }:
let
  # renovate: datasource=github-releases depName=mizchi/actrun
  version = "0.9.0";
  src = pkgs.fetchurl {
    url = "https://github.com/mizchi/actrun/releases/download/v${version}/actrun-linux-x64.tar.gz";
    hash = "sha256-9GVWlOb5yuVY+fJgQ5ftJUdQWB0fEGRIA7uO+4mQgQY=";
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
