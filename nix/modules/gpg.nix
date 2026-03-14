{ pkgs, lib, ... }:
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = "allow-loopback-pinentry";
  };

  home.activation.importGpgKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ "${"CI:-"}" = "true" ]; then
      $VERBOSE_ECHO "CI: GPG key import skipped"
    elif ! ${pkgs.doppler}/bin/doppler whoami &>/dev/null; then
      echo "WARNING: Doppler 未認証。'doppler login' 後に home-manager switch を再実行してください。"
    else
      $DRY_RUN_CMD bash -c "${pkgs.doppler}/bin/doppler secrets get GPG_PUBKEY --plain --project keys --config prd | ${pkgs.gnupg}/bin/gpg --import"
      $DRY_RUN_CMD bash -c "${pkgs.doppler}/bin/doppler secrets get GPG_SUBKEYS --plain --project keys --config prd | ${pkgs.gnupg}/bin/gpg --import"
      $DRY_RUN_CMD bash -c "${pkgs.doppler}/bin/doppler secrets get GPG_OWNERTRUST --plain --project keys --config prd | ${pkgs.gnupg}/bin/gpg --import-ownertrust"
    fi
  '';
}
