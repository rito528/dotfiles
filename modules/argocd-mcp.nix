{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=argoproj-labs/mcp-for-argocd
  version = "0.9.0";
  src = pkgs.fetchFromGitHub {
    owner = "argoproj-labs";
    repo = "mcp-for-argocd";
    rev = "v${version}";
    hash = "sha256-D94APT+e/PRxZ3JQSvc2N3sTFjSvu3br1MybcnGVd14=";
  };
  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "argocd-mcp";
    inherit version src;
    fetcherVersion = 4;
    hash = "sha256-Y/4rr3joxtG9VBNflv1YOGAKmxjx+AP69sVvFOiuQFU=";
  };
  package = pkgs.stdenv.mkDerivation {
    pname = "argocd-mcp";
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
      mkdir -p $out/lib/argocd-mcp $out/bin
      cp -r dist node_modules package.json $out/lib/argocd-mcp/
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/argocd-mcp \
        --add-flags "$out/lib/argocd-mcp/dist/index.js"
    '';
  };
in
{
  _module.args.argocdMcp = {
    command = "${pkgs.doppler}/bin/doppler";
    args = [
      "run"
      "--project"
      "mcp"
      "--config"
      "prd"
      "--"
      "${package}/bin/argocd-mcp"
      "stdio"
    ];
  };

  home.packages = [ package ];
}
