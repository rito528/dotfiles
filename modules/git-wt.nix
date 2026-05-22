{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=k1LoW/git-wt
  version = "0.28.0";
  git-wt = pkgs.stdenv.mkDerivation {
    pname = "git-wt";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/k1LoW/git-wt/releases/download/v${version}/git-wt_v${version}_linux_amd64.tar.gz";
      hash = "sha256-1wucLbCNBiuMN6iq+HZsB0NPkfyEFMkEMK7gE1M6rAI=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      tar xzf $src -C $out/bin git-wt
      chmod +x $out/bin/git-wt
    '';
  };
in
{
  home.packages = [ git-wt ];

  programs.zsh.initContent = ''
    eval "$(git-wt --init zsh)"
  '';
}
