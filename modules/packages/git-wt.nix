{ pkgs }:
let
  # renovate: datasource=github-releases depName=k1LoW/git-wt
  version = "0.26.1";
  src = pkgs.fetchurl {
    url = "https://github.com/k1LoW/git-wt/releases/download/v${version}/git-wt_v${version}_linux_amd64.tar.gz";
    hash = "sha256-MYSuG3m17sb4Qtw6qmBVyEQsast3feSfK0e9fZZ4z8o=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "git-wt";
  inherit version src;
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    tar xzf $src -C $out/bin git-wt
    chmod +x $out/bin/git-wt
  '';
}
