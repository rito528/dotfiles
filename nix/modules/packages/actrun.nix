{ pkgs }:
let
  # renovate: datasource=github-releases depName=mizchi/actrun
  version = "0.21.2";
  src = pkgs.fetchurl {
    url = "https://github.com/mizchi/actrun/releases/download/v${version}/actrun-linux-x64.tar.gz";
    hash = "sha256-VZonZb3dLXZ5JHSdBe8xZuJylOHm8XqP0QZXDTfOgjw=";
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
