{ pkgs, lib, ... }:
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    jq
    direnv
    starship
    nixfmt-rfc-style
    doppler
    gh
    ripgrep
  ];

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = "allow-loopback-pinentry";
  };

  programs.git = {
    enable = true;
    signing = {
      key = "F4022307254812F8";
      signByDefault = true;
    };
    ignores = [
      ".idea/"
      ".vscode/"
      ".env"
      ".env.local"
    ];
    settings = {
      user = {
        name = "rito528";
        email = "39003544+rito528@users.noreply.github.com";
      };
      gpg.program = "gpg";
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        hooksPath = "~/.config/git/hooks";
      };
      "credential \"https://github.com\"".helper = [
        ""
        "!/usr/bin/gh auth git-credential"
      ];
      "credential \"https://gist.github.com\"".helper = [
        ""
        "!/usr/bin/gh auth git-credential"
      ];
      push.autoSetupRemote = true;
    };
  };

  home.file.".bashrc" = {
    source = ../config/bashrc;
    force = true;
  };
  home.file.".bash_profile".source = ../config/bash_profile;

  home.file.".config/Code/User/settings.json".source = ../config/vscode/settings.json;

  home.file.".config/git/hooks/pre-commit" = {
    source = ../config/git/hooks/pre-commit;
    executable = true;
  };

  home.file.".secretlintrc.json".source = ../config/secretlintrc.json;

  home.file.".claude" = {
    source = ../config/claude;
    recursive = true;
  };

  xdg.configFile."git/ignore".force = true;

  home.activation.setupSshDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.ssh"
    $DRY_RUN_CMD chmod 700 "$HOME/.ssh"
  '';

  home.activation.importGpgKeys = lib.hm.dag.entryAfter [ "setupSshDirectory" ] ''
    if [ "''${CI:-}" = "true" ]; then
      $VERBOSE_ECHO "CI: GPG key import skipped"
    elif ! ${pkgs.doppler}/bin/doppler whoami &>/dev/null; then
      echo "WARNING: Doppler 未認証。'doppler login' 後に home-manager switch を再実行してください。"
    else
      ${pkgs.doppler}/bin/doppler secrets get GPG_PUBKEY --plain --project keys --config prd \
        | ${pkgs.gnupg}/bin/gpg --import
      ${pkgs.doppler}/bin/doppler secrets get GPG_SUBKEYS --plain --project keys --config prd \
        | ${pkgs.gnupg}/bin/gpg --import
      ${pkgs.doppler}/bin/doppler secrets get GPG_OWNERTRUST --plain --project keys --config prd \
        | ${pkgs.gnupg}/bin/gpg --import-ownertrust
    fi
  '';

  home.activation.importSshKeys = lib.hm.dag.entryAfter [ "setupSshDirectory" ] ''
    if [ "''${CI:-}" = "true" ]; then
      $VERBOSE_ECHO "CI: SSH key import skipped"
    elif ! ${pkgs.doppler}/bin/doppler whoami &>/dev/null; then
      echo "WARNING: Doppler 未認証。'doppler login' 後に home-manager switch を再実行してください。"
    else
      ${pkgs.doppler}/bin/doppler secrets get SSH_PRIVATE_KEY --plain --project keys --config prd \
        > "$HOME/.ssh/id_rsa"
      ${pkgs.doppler}/bin/doppler secrets get SSH_PUBLIC_KEY --plain --project keys --config prd \
        > "$HOME/.ssh/id_rsa.pub"
      $DRY_RUN_CMD chmod 600 "$HOME/.ssh/id_rsa"
      $DRY_RUN_CMD chmod 644 "$HOME/.ssh/id_rsa.pub"
    fi
  '';

  programs.home-manager.enable = true;
}
