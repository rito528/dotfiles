{ pkgs, ... }:
let
  grafanaMcp = import ./lib/grafana-mcp.nix { inherit pkgs; };
  skillEntries = builtins.readDir ../config/agents/skills;
  skillNames = builtins.filter (name: skillEntries.${name} == "directory") (
    builtins.attrNames skillEntries
  );
  claudeSkills = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = ../config/agents/skills + "/${name}";
    }) skillNames
  );
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    skills = claudeSkills;
    mcpServers.grafana = {
      inherit (grafanaMcp) command args;
    };
  };

  home.file.".claude/CLAUDE.md".source = ../config/claude/CLAUDE.md;

  home.file.".claude/settings.json".source = ../config/claude/settings.json;

  home.file.".claude/hooks/notify.sh" = {
    text = builtins.readFile ../config/claude/hooks/notify.sh;
    executable = true;
  };

  home.file.".claude/hooks/prevent-main-commit.sh" = {
    text = builtins.readFile ../config/claude/hooks/prevent-main-commit.sh;
    executable = true;
  };

  home.file.".claude/statusline.py" = {
    text = builtins.readFile ../config/claude/statusline.py;
    executable = true;
  };
}
