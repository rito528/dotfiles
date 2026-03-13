{ pkgs }:
let
  version = "3.1.15";
  src = pkgs.fetchFromGitHub {
    owner = "yoshiko-pg";
    repo = "difit";
    rev = "v${version}";
    hash = "sha256-Ut7/fkQPGwjFqb4Opw86EJs/+rUG5X9tn4JxcLFKfp0=";
  };
  pnpmDeps = pkgs.pnpm.fetchDeps {
    pname = "difit";
    inherit version src;
    fetcherVersion = 1;
    hash = "sha256-XoOgF/yHDEA7qffSbQiN106QsYyrAXFIbFf2Z0tZjts=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "difit";
  inherit version src;
  nativeBuildInputs = [
    pkgs.nodejs_22
    pkgs.pnpm.configHook
    pkgs.makeWrapper
  ];
  inherit pnpmDeps;
  buildPhase = ''
    pnpm run build
  '';
  installPhase = ''
    mkdir -p $out/lib/difit $out/bin
    cp -r dist node_modules package.json $out/lib/difit/
    find $out/lib/difit/node_modules -xtype l -delete
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/difit \
      --add-flags "$out/lib/difit/dist/cli/index.js"
  '';
}
