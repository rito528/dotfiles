{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      rust-overlay,
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
      pkgsWithRust = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
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
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust development environment";
        };
        scala = {
          path = ./templates/scala;
          description = "Scala development environment";
        };
        typescript = {
          path = ./templates/typescript;
          description = "TypeScript (pnpm) development environment";
        };
      };
      devShells.${system} = {
        rust = pkgsWithRust.mkShell {
          buildInputs = [
            pkgsWithRust.rust-bin.stable.latest.default
            pkgsWithRust.pkg-config
            pkgsWithRust.openssl
          ];
        };
        scala = pkgs.mkShell {
          buildInputs = [
            pkgs.jdk17
            pkgs.sbt
            pkgs.metals
            pkgs.scalafmt
          ];
        };
        typescript = pkgs.mkShell {
          buildInputs = [
            pkgs.nodejs_22
            pkgs.pnpm
          ];
        };
      };
    };
}
