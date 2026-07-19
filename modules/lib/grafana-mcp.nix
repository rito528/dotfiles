{ pkgs }:
let
  mcpGrafana = import ../packages/mcp-grafana.nix { inherit pkgs; };
in
{
  command = "${pkgs.doppler}/bin/doppler";
  args = [
    "run"
    "--project"
    "mcp"
    "--config"
    "prd"
    "--"
    "${mcpGrafana}/bin/mcp-grafana"
    "-t"
    "stdio"
    "--disable-write"
  ];
}
