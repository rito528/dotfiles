{ pkgs }:
let
  # renovate: datasource=github-releases depName=ryoppippi/ccusage
  version = "18.0.11";
  src = pkgs.fetchFromGitHub {
    owner = "ryoppippi";
    repo = "ccusage";
    rev = "v${version}";
    hash = "sha256-EzHFKZVq0okgRumxn6+4rfxDtz0jY6FBoO9eyrGX4ys=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "ccusage";
    inherit version src;
    fetcherVersion = 2;
    hash = "sha256-VUF70569dcVeH0o0e5+VcWMr18yXXVmvMrBauIWX9X8=";
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
