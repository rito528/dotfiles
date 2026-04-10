{
  pkgs,
  homeDirectory,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  codexConfig = {
    model = "gpt-5.4";
    model_reasoning_effort = "high";

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

  home.file.".codex/skills/create-pr".source = ../config/agents/skills/create-pr;
  home.file.".codex/skills/ensure-branch".source = ../config/agents/skills/ensure-branch;
  home.file.".codex/skills/git-commit".source = ../config/agents/skills/git-commit;
}
