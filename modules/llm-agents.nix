{
  pkgs,
  profile,
  ...
}:
let
  common = [ pkgs.llm-agents.claude-code ];
  byProfile = {
    personal = [
      pkgs.llm-agents.ccusage
      pkgs.llm-agents.copilot-cli
      pkgs.llm-agents.codex
      pkgs.llm-agents.opencode
    ];
    work = [ ];
  };
in
{
  home.packages = common ++ byProfile.${profile};
}
