{ pkgs }:
let
  # renovate: datasource=github-releases depName=yoshiko-pg/difit
  version = "5.0.12";
  src = pkgs.fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${version}";
    hash = "sha256-0qef7IhDOEPwLXhXe+vU52c505sH03xRbjUQUqgmyQ4=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "difit";
    inherit version src;
    fetcherVersion = 4;
    hash = "sha256-PLV82tBaOX7hDxRcV2owulK4EslaEcJGM1N1uuEQei8=";
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
