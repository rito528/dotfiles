{ pkgs }:

pkgs.buildGoModule rec {
  pname = "ccgate";
  # renovate: datasource=github-releases depName=tak848/ccgate
  version = "0.9.1";

  src = pkgs.fetchFromGitHub {
    owner = "tak848";
    repo = "ccgate";
    rev = "v${version}";
    hash = "sha256-kHTOgJE+zMeLZFk//kSqhq4iYXEPZ3IK0fNF80VNv34=";
  };

  vendorHash = "sha256-Uw/ZS7MVTxPhvv6M3vop27q97RNmu0S1VhXiQ4Fj02c=";

  subPackages = [ "." ];

  nativeCheckInputs = [
    pkgs.git
  ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  meta = {
    description = "LLM-powered PermissionRequest hook for coding agents";
    homepage = "https://github.com/tak848/ccgate";
    license = pkgs.lib.licenses.mit;
    mainProgram = "ccgate";
  };
}
