{
  description = "Scala development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pkgs.jdk17
          pkgs.sbt
          pkgs.bloop
          pkgs.metals
          pkgs.scalafmt
        ];
      };
    };
}
