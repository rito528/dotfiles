{
  pkgs,
  grafanaMcp,
  codexTaskChecker,
  ...
}:
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
  home.file.".pi/agent/extensions/task-check.ts".text = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
    import { installObserver } from "${../config/pi/task-check}/observe.ts";
    import { installQuestionTool } from "${../config/pi/task-check}/question.ts";

    export default function (pi: ExtensionAPI) {
      installQuestionTool(pi);
      installObserver(pi, "${codexTaskChecker}/bin/codex-task-check");
    }
  '';
  home.file.".pi/agent/extensions/grafana.ts".text = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

    export default function (pi: ExtensionAPI) {
      pi.registerMcpServer("grafana", ${grafanaConfig});
    }
  '';
}
