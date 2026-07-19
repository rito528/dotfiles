{
  pkgs,
  grafanaMcp,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };
  pluginManifest = jsonFormat.generate "claude-grafana-mcp-plugin.json" {
    name = "grafana-mcp";
  };
  mcpConfig = jsonFormat.generate "claude-grafana-mcp.json" {
    mcpServers.grafana = {
      inherit (grafanaMcp) command args;
      type = "stdio";
    };
  };
  grafanaMcpPlugin = pkgs.runCommand "claude-grafana-mcp-plugin" { } ''
    install -Dm644 ${pluginManifest} "$out/grafana-mcp/.claude-plugin/plugin.json"
    install -Dm644 ${mcpConfig} "$out/grafana-mcp/.mcp.json"
  '';
  claudeSkills = pkgs.symlinkJoin {
    name = "claude-skills";
    paths = [
      ../config/agents/skills
      grafanaMcpPlugin
    ];
  };
in
{
  home.file.".claude/CLAUDE.md".source = ../config/claude/CLAUDE.md;

  home.file.".claude/settings.json".source = ../config/claude/settings.json;

  home.file.".claude/skills" = {
    source = claudeSkills;
  };

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
