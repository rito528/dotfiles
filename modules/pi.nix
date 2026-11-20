{ pkgs, grafanaMcp, ... }:
let
  grafanaConfig = builtins.toJSON (
    grafanaMcp
    // {
      exposure = "deferred";
      timeout = 120;
    }
  );
in
{
  home.packages = [ pkgs.llm-agents.pi ];
  home.file.".pi/agent/extensions/agent-task.ts".source = ../config/pi/agent-task.ts;
  home.file.".pi/agent/extensions/subagent".source = ../config/pi/subagent;
  home.file.".pi/agent/extensions/grafana.ts".text = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

    export default function (pi: ExtensionAPI) {
      pi.registerMcpServer("grafana", ${grafanaConfig});
    }
  '';
}
