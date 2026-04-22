{
  description = "seichi-portal-backend development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, rust-overlay, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ rust-overlay.overlays.default ];
      };
      treesitterRuntime = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        plugins: with plugins; [
          rust
          sql
        ]
      );
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          (pkgs.rust-bin.stable.latest.default.override {
            extensions = [
              "rust-src"
              "rust-analyzer"
            ];
          })
          pkgs.pkg-config
          pkgs.openssl
          pkgs.cargo-make
          pkgs.sqlx-cli
          pkgs.taplo
        ];
        shellHook = ''
          export NVIM_TREESITTER_RUNTIME_PROJECT="${treesitterRuntime}"
        '';
      };
    };
}
