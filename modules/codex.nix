{
  pkgs,
  homeDirectory,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  codexRules = pkgs.writeText "codex-default.rules" ''
    prefix_rule(pattern=["rg"], decision="allow")
    prefix_rule(pattern=["grep"], decision="allow")
    prefix_rule(pattern=["ls"], decision="allow")
    prefix_rule(pattern=["tree"], decision="allow")
    prefix_rule(pattern=["pwd"], decision="allow")

    prefix_rule(pattern=["git", "status"], decision="allow")
    prefix_rule(pattern=["git", "diff"], decision="allow")
    prefix_rule(pattern=["git", "log"], decision="allow")
    prefix_rule(pattern=["git", "branch"], decision="allow")
    prefix_rule(pattern=["git", "fetch"], decision="allow")
    prefix_rule(pattern=["git", "switch"], decision="allow")
    prefix_rule(pattern=["git", "pull"], decision="allow")

    prefix_rule(pattern=["shellcheck"], decision="allow")
    prefix_rule(pattern=["nixfmt"], decision="allow")
    prefix_rule(pattern=["home-manager", "build"], decision="allow")
    prefix_rule(pattern=["nix"], decision="allow")
    prefix_rule(pattern=["nix-build"], decision="allow")

    prefix_rule(pattern=["gh", "issue", "view"], decision="allow")
    prefix_rule(pattern=["gh", "issue", "list"], decision="allow")
    prefix_rule(pattern=["gh", "pr", "list"], decision="allow")
    prefix_rule(pattern=["gh", "pr", "view"], decision="allow")
    prefix_rule(pattern=["gh", "run", "view"], decision="allow")
    prefix_rule(pattern=["gh", "run", "list"], decision="allow")
  '';
  codexConfig = {
    model = "gpt-5.4";
    model_reasoning_effort = "medium";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write.writable_roots = [ "/tmp" ];

    projects."${homeDirectory}".trust_level = "trusted";

    notice.model_migrations."gpt-5.3-codex" = "gpt-5.4";

    tui.status_line = [
      "model-with-reasoning"
      "context-remaining"
      "current-dir"
      "five-hour-limit"
      "weekly-limit"
    ];

    plugins."google-calendar@openai-curated".enabled = true;
    plugins."github@openai-curated".enabled = true;

    features.codex_git_commit = true;
  };
in
{
  home.file.".codex/config.toml" = {
    force = true;
    source = tomlFormat.generate "codex-config.toml" codexConfig;
  };

  home.file.".codex/rules/default.rules" = {
    force = true;
    source = codexRules;
  };
}
