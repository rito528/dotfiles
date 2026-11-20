{ pkgs, ... }:
{
  home.packages = [ pkgs.llm-agents.pi ];
  home.file.".pi/agent/extensions/agent-task.ts".source = ../config/pi/agent-task.ts;
}
