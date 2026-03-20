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
      mkShellWithZsh = mkPkgs: args: mkPkgs.mkShell ({ SHELL = "${pkgs.zsh}/bin/zsh"; } // args);
    in
    {
      packages.${system} = npmPackages // extraPackages;
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
      devShells.${system} = {
        rust = mkShellWithZsh pkgsWithRust {
          buildInputs = [
            pkgsWithRust.rust-bin.stable.latest.default
            pkgsWithRust.pkg-config
            pkgsWithRust.openssl
          ];
        };
        scala = mkShellWithZsh pkgs {
          buildInputs = [
            pkgs.jdk17
            pkgs.sbt
            pkgs.metals
            pkgs.scalafmt
            pkgs.stdenv.cc.cc.lib
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          '';
        };
        typescript = mkShellWithZsh pkgs {
          buildInputs = [
            pkgs.nodejs_22
            pkgs.pnpm
          ];
        };
        seichi-assist = mkShellWithZsh pkgs {
          buildInputs = [
            pkgs.jdk17
            pkgs.sbt
            pkgs.metals
            pkgs.scalafmt
            pkgs.stdenv.cc.cc.lib
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          '';
        };
        seichi-infra = mkShellWithZsh pkgs {
          buildInputs = [
            pkgs.terraform
            pkgs.tflint
            pkgs.kubectl
            pkgs.kubernetes-helm
          ];
        };
        seichi-portal-backend = mkShellWithZsh pkgsWithRust {
          buildInputs = [
            pkgsWithRust.rust-bin.stable.latest.default
            pkgsWithRust.pkg-config
            pkgsWithRust.openssl
            pkgsWithRust.cargo-make
            pkgsWithRust.sqlx-cli
          ];
        };
        seichi-portal-frontend = mkShellWithZsh pkgs {
          buildInputs = [
            pkgs.nodejs_22
            pkgs.pnpm
          ];
        };
      };
    };
}
