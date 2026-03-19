{ pkgs }:
let
  # renovate: datasource=github-releases depName=ryoppippi/ccusage
  version = "18.0.10";
  src = pkgs.fetchFromGitHub {
    owner = "ryoppippi";
    repo = "ccusage";
    rev = "v${version}";
    hash = "sha256-6KmSj2wgnkwJNnKaTmscbY+7fy2l6JHci3x3m/CV/Qg=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "ccusage";
    inherit version src;
    fetcherVersion = 2;
    hash = "sha256-6RNmV4fkUCs6mVdQ5Wv2wo8hqvI0BM/T87Kb96CmeF4=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "ccusage";
  inherit version src;
  nativeBuildInputs = [
    pkgs.nodejs_24
    pkgs.pnpm
    pkgs.pnpmConfigHook
    pkgs.makeWrapper
  ];
  inherit pnpmDeps;
  buildPhase = ''
    cd apps/ccusage
    ../../node_modules/.pnpm/node_modules/.bin/tsdown
    cd ../..
  '';
  installPhase = ''
    mkdir -p $out/lib/ccusage $out/bin
    cp -r apps/ccusage/dist apps/ccusage/node_modules apps/ccusage/package.json $out/lib/ccusage/
    find $out/lib/ccusage/node_modules -xtype l -delete
    makeWrapper ${pkgs.nodejs_24}/bin/node $out/bin/ccusage \
      --add-flags "$out/lib/ccusage/dist/index.js"
  '';
}
