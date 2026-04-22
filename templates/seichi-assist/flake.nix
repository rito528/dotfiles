{
  description = "SeichiAssist development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      treesitterRuntime = pkgs.vimPlugins.nvim-treesitter.withPlugins (
        plugins: with plugins; [
          scala
        ]
      );
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.jdk17
          pkgs.sbt
          pkgs.metals
          pkgs.scalafmt
          pkgs.stdenv.cc.cc.lib
        ];
        shellHook = ''
          export NVIM_TREESITTER_RUNTIME_PROJECT="${treesitterRuntime}"
          export LD_LIBRARY_PATH="${pkgs.stdenv.cc.cc.lib}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        '';
      };
    };
}
