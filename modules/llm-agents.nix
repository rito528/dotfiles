{ pkgs, ... }:
{
  home.packages = [
    pkgs.llm-agents.ccusage
    pkgs.llm-agents.claude-code
    pkgs.llm-agents.copilot-cli
    pkgs.llm-agents.codex
    pkgs.llm-agents.gemini-cli
  ];
}
