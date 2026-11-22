{
  pkgs,
  lib,
  homeDirectory,
  grafanaMcp,
  codexTaskChecker,
  ...
}:
let
  codexCompactionVersion = "0.2.6";
  codexCompaction = pkgs.fetchzip {
    url = "https://registry.npmjs.org/pi-codex-compaction/-/pi-codex-compaction-${codexCompactionVersion}.tgz";
    hash = "sha256-XzIR/PTA+Cae+sM/BR/5eLEV4aHUfiJTEmfByP+OqcI=";
  };
  grafanaConfig = builtins.toJSON (
    grafanaMcp
    // {
      exposure = "deferred";
      timeout = 120;
    }
  );
  setDefaultModel = pkgs.writeShellScript "pi-default-model" ''
    set -eu
    settings=$1
    if [[ -L "$settings" ]]; then
      echo "Pi settings must be writable, not a symlink: $settings" >&2
      exit 1
    fi
    tmp=$(mktemp "$settings.XXXXXX")
    trap 'rm -f "$tmp"' EXIT
    if [[ ! -e "$settings" ]]; then
      printf '{}\n' > "$tmp"
      input=$tmp
    else
      input=$settings
    fi
    updated=$(${lib.getExe pkgs.jq} -es '
      if length == 1 and (.[0] | type == "object") then .[0]
      else error("Pi settings.json must contain one JSON object") end
      | .defaultProvider = "openai-codex"
      | .defaultModel = "gpt-6.2-sol"
    ' "$input")
    printf '%s\n' "$updated" > "$tmp"
    if ! cmp -s "$tmp" "$settings"; then
      mv -f "$tmp" "$settings"
    fi
  '';
in
{
  home.packages = [ pkgs.llm-agents.pi ];

  # Pi 自身が書き込めるように、既存の設定を残してモデル指定だけを更新する。
  home.activation.piDefaultModel = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run mkdir -p "${homeDirectory}/.pi/agent"
    run ${setDefaultModel} "${homeDirectory}/.pi/agent/settings.json"
  '';

  # パッケージの公開 API を使い、既定の入口が行うインストール通知は呼び出さない。
  home.file.".pi/agent/extensions/pi-codex-compaction.ts".text = ''
    export { registerAutomaticCompaction as default } from "${codexCompaction}/src/index.ts";
  '';
  home.file.".pi/agent/extensions/agent-task.ts".source = ../config/pi/agent-task.ts;
  home.file.".pi/agent/extensions/subagent".source = ../config/pi/subagent;
  home.file.".pi/agent/extensions/subscription-usage.ts".text = ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
    import { installSubscriptionUsage } from "${../config/pi/subscription-usage.ts}";

    export default function (pi: ExtensionAPI) {
      installSubscriptionUsage(pi, "${lib.getExe pkgs.codex}");
    }
  '';
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
