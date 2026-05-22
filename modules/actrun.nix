{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=mizchi/actrun
  version = "0.29.0";
  actrun = pkgs.stdenv.mkDerivation {
    pname = "actrun";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/mizchi/actrun/releases/download/v${version}/actrun-linux-x64.tar.gz";
      hash = "sha256-B8WPrLKxhJ+7yrUfyvmdLA+NMq9W82jbl5Korx2HOKY=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      tar xzf $src -C $out/bin
      chmod +x $out/bin/actrun
    '';
  };
in
{
  home.packages = [ actrun ];
}
