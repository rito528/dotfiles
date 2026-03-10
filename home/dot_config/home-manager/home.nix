{ pkgs, ... }:
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    jq
    direnv
    starship
    nixfmt-rfc-style
  ];

  programs.home-manager.enable = true;
}
