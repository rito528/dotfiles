{
  pkgs,
  homeDirectory,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  codexConfig = {
    model = "gpt-5.4";
    model_reasoning_effort = "medium";

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
}
