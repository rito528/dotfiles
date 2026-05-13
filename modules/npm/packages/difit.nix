{ pkgs }:
let
  # renovate: datasource=github-releases depName=yoshiko-pg/difit
  version = "5.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${version}";
    hash = "sha256-4YFja6wQmWfRlUmXnUwxAO2IF9T17azNEXn5X4i+YMc=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "difit";
    inherit version src;
    fetcherVersion = 2;
    hash = "sha256-oY0QGktG0PZ4Wq6/G6hxWko+HxkyRjkSDecV/ec6q7M=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "difit";
  inherit version src;
  nativeBuildInputs = [
    pkgs.nodejs_22
    pkgs.pnpm
    pkgs.pnpmConfigHook
    pkgs.makeWrapper
  ];
  inherit pnpmDeps;
  buildPhase = ''
    pnpm run build
  '';
  installPhase = ''
    mkdir -p $out/lib/difit $out/bin
    cp -r dist node_modules package.json packages $out/lib/difit/
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/difit \
      --add-flags "$out/lib/difit/dist/cli/index.js"
  '';
}
