{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "switch-branch-with-refresh";
      runtimeInputs = [ pkgs.git ];
      text = builtins.readFile ./script.sh;
    })
  ];
}
