{
  lib,
  pkgs,
  profile,
  ...
}:
{
  home.packages = lib.optionals (profile == "personal") [
    (pkgs.writeShellApplication {
      name = "agent-task";
      runtimeInputs = [
        pkgs.git
        pkgs.python3
      ];
      text = ''
        exec python3 -B ${./agent_task.py} "$@"
      '';
    })
  ];
}
