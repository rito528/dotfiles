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
    {
      nixpkgs,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
            "github-copilot-cli"
          ];
      };
      mkHomeConfig =
        username: homeDirectory: personal:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./home.nix ];
          extraSpecialArgs = {
            inherit username homeDirectory personal;
          };
        };
    in
    let
      loadPackagesDir =
        dir:
        let
          allFiles = builtins.readDir dir;
          nixFiles = builtins.filter (name: name != "default.nix" && builtins.match ".*\\.nix" name != null) (
            builtins.attrNames allFiles
          );
        in
        builtins.listToAttrs (
          map (name: {
            name = builtins.replaceStrings [ ".nix" ] [ "" ] name;
            value = import (dir + "/${name}") { inherit pkgs; };
          }) nixFiles
        );
      npmPackages = loadPackagesDir ./modules/npm/packages;
      extraPackages = loadPackagesDir ./modules/packages;
    in
    {
      packages.${system} = npmPackages // extraPackages;
      homeConfigurations = {
        "rito528" = mkHomeConfig "rito528" "/home/rito528" {
          name = "rito528";
          email = "39003544+rito528@users.noreply.github.com";
          gpgKey = "F4022307254812F8";
        };
        "testuser" = mkHomeConfig "testuser" "/home/testuser" {
          name = "testuser";
          email = "testuser@example.com";
          gpgKey = "";
        };
      };
      templates = {
        seichi-assist = {
          path = ./templates/seichi-assist;
          description = "SeichiAssist development environment";
        };
        seichi-infra = {
          path = ./templates/seichi-infra;
          description = "seichi-infra development environment";
        };
        seichi-portal-backend = {
          path = ./templates/seichi-portal-backend;
          description = "seichi-portal-backend development environment";
        };
        seichi-portal-frontend = {
          path = ./templates/seichi-portal-frontend;
          description = "seichi-portal-frontend development environment";
        };
      };
    };
}
