{ pkgs }:
let
  # renovate: datasource=github-releases depName=yoshiko-pg/difit
  version = "4.0.5";
  src = pkgs.fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${version}";
    hash = "sha256-BSoTn5uoOhgFG2F4jvw8HepUgx1Cw4eKvglM/hb6z1U=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "difit";
    inherit version src;
    fetcherVersion = 2;
    hash = "sha256-CaKoe5MCiwTM1fNHS1SC79EV0pS96hlbehz9fs0og4g=";
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
