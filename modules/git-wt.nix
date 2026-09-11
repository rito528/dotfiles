{ pkgs, ... }:
let
  # renovate: datasource=github-releases depName=k1LoW/git-wt
  version = "0.29.3";
  git-wt = pkgs.stdenv.mkDerivation {
    pname = "git-wt";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://github.com/k1LoW/git-wt/releases/download/v${version}/git-wt_v${version}_linux_amd64.tar.gz";
      hash = "sha256-j8Z7NOkr9h/VCe53ffjY1TRCqjwNkI5/zP+5cqrVqes=";
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
