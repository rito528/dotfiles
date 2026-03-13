{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
          ];
      };
      mkHomeConfig =
        username: homeDirectory:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit username homeDirectory;
          };
        };
    in
    let
      npmPackagesDir = ./modules/npm/packages;
      allFiles = builtins.readDir npmPackagesDir;
      nixFiles = builtins.filter (name: builtins.match ".*\\.nix" name != null) (
        builtins.attrNames allFiles
      );
      npmPackages = builtins.listToAttrs (
        map (name: {
          name = builtins.replaceStrings [ ".nix" ] [ "" ] name;
          value = import (npmPackagesDir + "/${name}") { inherit pkgs; };
        }) nixFiles
      );
    in
    {
      packages.${system} = npmPackages;
      homeConfigurations = {
        "rito528" = mkHomeConfig "rito528" "/home/rito528";
        "testuser" = mkHomeConfig "testuser" "/home/testuser";
      };
    };
}
