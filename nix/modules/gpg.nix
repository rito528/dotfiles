{ pkgs, lib, ... }:
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = "allow-loopback-pinentry";
  };

  home.activation.setupSshDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.ssh"
    $DRY_RUN_CMD chmod 700 "$HOME/.ssh"
  '';

  home.activation.importGpgKeys = lib.hm.dag.entryAfter [ "setupSshDirectory" ] ''
    if [ "${CI:-}" = "true" ]; then
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
    if [ "${CI:-}" = "true" ]; then
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
}
