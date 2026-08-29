{
  pkgs,
  profile,
  grafanaMcp ? null,
  argocdMcp ? null,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };
  grafanaMcpPlugin =
    let
      pluginManifest = jsonFormat.generate "claude-grafana-mcp-plugin.json" {
        name = "grafana-mcp";
      };
      mcpConfig = jsonFormat.generate "claude-grafana-mcp.json" {
        mcpServers.grafana = {
          inherit (grafanaMcp) command args;
          type = "stdio";
        };
      };
    in
    pkgs.runCommand "claude-grafana-mcp-plugin" { } ''
      install -Dm644 ${pluginManifest} "$out/grafana-mcp/.claude-plugin/plugin.json"
      install -Dm644 ${mcpConfig} "$out/grafana-mcp/.mcp.json"
    '';
  argocdMcpPlugin =
    let
      pluginManifest = jsonFormat.generate "claude-argocd-mcp-plugin.json" {
        name = "argocd-mcp";
      };
      mcpConfig = jsonFormat.generate "claude-argocd-mcp.json" {
        mcpServers.argocd = {
          inherit (argocdMcp) command args;
          type = "stdio";
        };
      };
    in
    pkgs.runCommand "claude-argocd-mcp-plugin" { } ''
      install -Dm644 ${pluginManifest} "$out/argocd-mcp/.claude-plugin/plugin.json"
      install -Dm644 ${mcpConfig} "$out/argocd-mcp/.mcp.json"
    '';
  extraSkillsByProfile = {
    personal = [
      grafanaMcpPlugin
      argocdMcpPlugin
    ];
    work = [ ];
  };
  claudeSkills = pkgs.symlinkJoin {
    name = "claude-skills";
    paths = [
      ../config/agents/skills
    ]
    ++ extraSkillsByProfile.${profile};
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
