{
  description = "Home Manager configuration";

  nixConfig = {
    extra-substituters = [
      "https://cache.numtide.com"
      "https://rito528-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      "rito528-dotfiles.cachix.org-1:Kp/hDIx4sR31gHfT0z0D1RxjdpSrh47nHqzOtDXL/mE="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents.url = "github:numtide/llm-agents.nix";
    takt = {
      url = "github:nrslib/takt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nixvim,
      nix-darwin,
      llm-agents,
      takt,
      ...
    }:
    let
      nixpkgsOverlays = [ llm-agents.overlays.shared-nixpkgs ];
      nixpkgsAllowUnfreePredicate =
        pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [
          "claude-code"
          "copilot.vim"
          "copilot-cli"
          "barbar.nvim"
          "antigravity-cli"
        ];
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = nixpkgsOverlays;
          config.allowUnfreePredicate = nixpkgsAllowUnfreePredicate;
        };
      mkHomeConfig =
        system: username: homeDirectory: identity: profile:
        assert builtins.elem profile [
          "personal"
          "work"
        ];
        home-manager.lib.homeManagerConfiguration {
          pkgs = mkPkgs system;
          modules = [
            nixvim.homeModules.nixvim
            ./home.nix
          ];
          extraSpecialArgs = {
            inherit
              username
              homeDirectory
              identity
              profile
              takt
              ;
          };
        };
      mkDarwinConfig =
        system: username: homeDirectory: identity: profile:
        assert builtins.elem profile [
          "personal"
          "work"
        ];
        nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            {
              nixpkgs.overlays = nixpkgsOverlays;
              nixpkgs.config.allowUnfreePredicate = nixpkgsAllowUnfreePredicate;
            }
            ./modules/darwin
            {
              users.users.${username} = {
                name = username;
                home = homeDirectory;
              };
              system.primaryUser = username;
            }
            home-manager.darwinModules.home-manager
            {
              home-manager.extraSpecialArgs = {
                inherit
                  username
                  homeDirectory
                  identity
                  profile
                  takt
                  ;
              };
              home-manager.users.${username} = {
                imports = [
                  nixvim.homeModules.nixvim
                  ./home.nix
                ];
              };
            }
          ];
        };
    in
    let
      loadPackagesDir =
        dir: pkgs:
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
      npmPackages = loadPackagesDir ./modules/npm/packages (mkPkgs "x86_64-linux");

      # 各マシン向け homeConfigurations の定義。新しいマシンを追加する場合はここにエントリを足す。
      machines = {
        rito528 = {
          system = "x86_64-linux";
          username = "rito528";
          homeDirectory = "/home/rito528";
          identity = {
            name = "rito528";
            email = "39003544+rito528@users.noreply.github.com";
            gpgKey = "F4022307254812F8";
          };
          profile = "personal";
        };
        testuser = {
          system = "x86_64-linux";
          username = "testuser";
          homeDirectory = "/home/testuser";
          identity = {
            name = "testuser";
            email = "testuser@example.com";
            gpgKey = "";
          };
          profile = "personal";
        };
        # profile 配線確認用。実マシンではない。
        testuser-work = {
          system = "x86_64-linux";
          username = "testuser";
          homeDirectory = "/home/testuser";
          identity = {
            name = "testuser";
            email = "testuser@example.com";
            gpgKey = "";
          };
          profile = "work";
        };
      };

      # 各マシン向け darwinConfigurations の定義。実 Mac が判明したらここにエントリを足す。
      darwinMachines = {
        # aarch64-darwin 向け評価確認用。実マシンではない。
        testuser-darwin = {
          system = "aarch64-darwin";
          username = "testuser";
          homeDirectory = "/Users/testuser";
          identity = {
            name = "testuser";
            email = "testuser@example.com";
            gpgKey = "";
          };
          profile = "personal";
        };
      };
    in
    {
      packages.x86_64-linux = npmPackages;
      homeConfigurations = builtins.mapAttrs (
        _: cfg: mkHomeConfig cfg.system cfg.username cfg.homeDirectory cfg.identity cfg.profile
      ) machines;
      darwinConfigurations = builtins.mapAttrs (
        _: cfg: mkDarwinConfig cfg.system cfg.username cfg.homeDirectory cfg.identity cfg.profile
      ) darwinMachines;
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
