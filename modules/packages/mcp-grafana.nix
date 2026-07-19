{ pkgs }:
let
  # renovate: datasource=github-releases depName=grafana/mcp-grafana
  version = "0.14.0";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "mcp-grafana";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/grafana/mcp-grafana/releases/download/v${version}/mcp-grafana_Linux_x86_64.tar.gz";
    hash = "sha256-gcWrHESi580nBCCywjWHvrYqtZgvLd6LgAQFqp7G6Cw=";
  };

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 mcp-grafana "$out/bin/mcp-grafana"

    runHook postInstall
  '';

  meta = {
    description = "MCP server for Grafana";
    homepage = "https://github.com/grafana/mcp-grafana";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "mcp-grafana";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
  };
}
