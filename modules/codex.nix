{
  pkgs,
  lib,
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
    model_reasoning_effort = "medium";
    suppress_unstable_features_warning = true;
    approvals_reviewer = "auto_review";
    sandbox_mode = "workspace-write";
    sandbox_workspace_write.writable_roots = [ "/tmp" ];

    projects."${homeDirectory}".trust_level = "trusted";

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
  codexConfigFile = tomlFormat.generate "codex-config.toml" codexConfig;
in
{
  # config.toml は Codex がトラスト設定などを書き込むため、symlink ではなく
  # mutable なコピーとして配置する。home-manager switch のたびに上書きされる。
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "${homeDirectory}/.codex"
    $DRY_RUN_CMD cp -f ${codexConfigFile} "${homeDirectory}/.codex/config.toml"
    $DRY_RUN_CMD chmod 644 "${homeDirectory}/.codex/config.toml"
  '';

  home.file.".codex/rules/default.rules" = {
    force = true;
    source = codexRules;
  };
}
