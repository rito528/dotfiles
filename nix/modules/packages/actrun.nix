{ pkgs }:
let
  # renovate: datasource=github-releases depName=mizchi/actrun
  version = "0.9.1";
  src = pkgs.fetchurl {
    url = "https://github.com/mizchi/actrun/releases/download/v${version}/actrun-linux-x64.tar.gz";
    hash = "sha256-o6Pv12+ztkQ55/2E/RiVmd612EoZBqyv0JHiJxekAGw=";
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
