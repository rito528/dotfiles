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
  codexConfig = {
    model = "gpt-6-sol";
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
  # config.toml は Codex がトラスト設定などを書き込むため、symlink ではなく
  # mutable なコピーとして配置する。home-manager switch のたびに上書きされる。
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${homeDirectory}/.codex"
    $DRY_RUN_CMD install -m 644 ${codexConfigFile} "${homeDirectory}/.codex/config.toml"
  '';

}
