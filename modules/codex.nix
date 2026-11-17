{
  pkgs,
  lib,
  homeDirectory,
  grafanaMcp,
  argocdMcp,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  taskCheckAssets = pkgs.runCommand "codex-task-check-assets" { } ''
    mkdir -p "$out/libexec/codex-task-check"
    cp ${../config/codex/task-check}/task_check.py \
      ${../config/codex/task-check}/judge_prompt.txt \
      ${../config/codex/task-check}/judge_schema.json \
      ${../config/codex/task-check}/judge_models.json \
      "$out/libexec/codex-task-check/"
  '';
  taskCheck = pkgs.writeShellApplication {
    name = "codex-task-check";
    text = ''
      exec ${pkgs.python3}/bin/python3 ${taskCheckAssets}/libexec/codex-task-check/task_check.py --codex ${pkgs.codex}/bin/codex "$@"
    '';
  };
  taskCheckHook = kind: timeout: {
    type = "command";
    command = "${taskCheck}/bin/codex-task-check ${kind}";
    inherit timeout;
    async = false;
  };
  taskCheckHooks = {
    UserPromptSubmit = [ { hooks = [ (taskCheckHook "record" 5) ]; } ];
    PreToolUse = [
      {
        matcher = "^request_user_input(_async)?$";
        hooks = [ (taskCheckHook "question" 40) ];
      }
    ];
    Stop = [ { hooks = [ (taskCheckHook "stop" 40) ]; } ];
  };
  # Codex hashes compact, recursively sorted JSON after normalizing hook defaults.
  # Only these Home Manager-owned definitions receive persisted trust.
  taskCheckHookState =
    lib.mapAttrs'
      (
        event: event_name:
        let
          identity = {
            inherit event_name;
          }
          // builtins.head taskCheckHooks.${event};
        in
        lib.nameValuePair "${homeDirectory}/.codex/config.toml:${event_name}:0:0" {
          trusted_hash = "sha256:${builtins.hashString "sha256" (builtins.toJSON identity)}";
        }
      )
      {
        UserPromptSubmit = "user_prompt_submit";
        PreToolUse = "pre_tool_use";
        Stop = "stop";
      };
  codexConfig = {
    model = "gpt-6.1-sol";
    model_reasoning_effort = "medium";
    suppress_unstable_features_warning = true;
    approval_policy = "on-request";
    approvals_reviewer = "auto_review";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write = {
      writable_roots = [ "/tmp" ];
      network_access = true;
    };

    projects."${homeDirectory}".trust_level = "trusted";

    tui = {
      fullscreen_transcript = false;
      notifications = [
        "agent-turn-complete"
        "approval-requested"
      ];
      notification_condition = "unfocused";
      status_line = [
        "model-with-reasoning"
        "context-remaining"
        "git-branch"
        "current-dir"
        "five-hour-limit"
        "weekly-limit"
      ];
    };

    plugins."github@openai-curated".enabled = true;

    hooks = taskCheckHooks // {
      state = taskCheckHookState;
    };

    mcp_servers.grafana = {
      inherit (grafanaMcp) command args;
      startup_timeout_sec = 120;
    };

    mcp_servers.argocd = {
      inherit (argocdMcp) command args;
      startup_timeout_sec = 120;
    };

    features = {
      network_proxy = {
        enabled = true;
        domains = {
          "**.github.com" = "allow";
          "**.githubusercontent.com" = "allow";
        };
      };
    };
  };
  codexConfigFile = tomlFormat.generate "codex-config.toml" codexConfig;
in
{
  home.packages = [ taskCheck ];
  home.file.".codex/AGENTS.md".source = ../config/agents/AGENTS.md;

  # config.toml は Codex がトラスト設定などを書き込むため、symlink ではなく
  # mutable なコピーとして配置する。home-manager switch のたびに上書きされる。
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${homeDirectory}/.codex"
    $DRY_RUN_CMD install -m 644 ${codexConfigFile} "${homeDirectory}/.codex/config.toml"
  '';

}
