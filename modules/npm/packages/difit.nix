{ pkgs }:
let
  # renovate: datasource=github-releases depName=yoshiko-pg/difit
  version = "5.0.5";
  src = pkgs.fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${version}";
    hash = "sha256-SLBpi4YwjBu0PCW43jdCWsDRkOUN6jn1aHtnKHbo2+I=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "difit";
    inherit version src;
    fetcherVersion = 3;
    hash = "sha256-og4xTW7MJtBiOfanKIk6pjpmonnNmshfBNOSshT8xwQ=";
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
