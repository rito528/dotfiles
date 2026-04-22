{
  description = "seichi-infra development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "terraform" ];
      };
      treesitterRuntime = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        plugins: with plugins; [
          hcl
        ]
      );
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.terraform
          pkgs.tflint
          pkgs.kubectl
          pkgs.kubernetes-helm
        ];
        shellHook = ''
          export NVIM_TREESITTER_RUNTIME_PROJECT="${treesitterRuntime}"
        '';
      };
    };
}
