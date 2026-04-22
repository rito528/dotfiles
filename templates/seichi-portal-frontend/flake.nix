{
  description = "seichi-portal-frontend development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      treesitterRuntime = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        plugins: with plugins; [
          javascript
          typescript
        ]
      );
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.nodejs_22
          pkgs.pnpm
        ];
        shellHook = ''
          export NVIM_TREESITTER_RUNTIME_PROJECT="${treesitterRuntime}"
        '';
      };
    };
}
