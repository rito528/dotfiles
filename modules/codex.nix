{
  pkgs,
  homeDirectory,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
  shellUtilityPrefixes = [
    "rg"
    "grep"
    "ls"
    "tree"
    "pwd"
    "mkdir"
    "cat"
  ];
  gitReadPrefixes = [
    "git status"
    "git diff"
    "git log"
    "git branch"
    "git branch --show-current"
    "git fetch"
    "git switch"
    "git switch -c"
    "git pull"
  ];
  gitLocalWritePrefixes = [
    "git add"
    "git commit"
    "git commit --no-gpg-sign"
  ];
  buildPrefixes = [
    "shellcheck"
    "nixfmt"
    "home-manager build"
    "nix"
    "nix-build"
    "cargo"
    "sbt"
    "sbtn"
  ];
  dockerLocalPrefixes = [
    "docker build"
    "docker buildx build"
    "docker ps"
    "docker images"
  ];
  tempFilePrefixes = [
    "mktemp"
    "printf"
  ];
  githubReadPrefixes = [
    "gh issue view"
    "gh issue list"
    "gh pr list"
    "gh pr view"
    "gh run view"
    "gh run list"
  ];
  allowCommandPrefixes =
    shellUtilityPrefixes
    ++ gitReadPrefixes
    ++ gitLocalWritePrefixes
    ++ buildPrefixes
    ++ dockerLocalPrefixes
    ++ tempFilePrefixes
    ++ githubReadPrefixes;
  renderPrefixRule =
    prefix:
    let
      pattern = pkgs.lib.splitString " " prefix;
    in
    ''prefix_rule(pattern=${builtins.toJSON pattern}, decision="allow")'';
  codexRules = pkgs.writeText "codex-default.rules" (
    builtins.concatStringsSep "\n" (map renderPrefixRule allowCommandPrefixes) + "\n"
  );
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
