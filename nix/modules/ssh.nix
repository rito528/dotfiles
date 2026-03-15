{ pkgs, lib, ... }:
{
  home.activation.setupSshDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.ssh"
    $DRY_RUN_CMD chmod 700 "$HOME/.ssh"
  '';

  home.activation.importSshKeys = lib.hm.dag.entryAfter [ "setupSshDirectory" ] ''
    if [ "${"CI:-"}" = "true" ]; then
      $VERBOSE_ECHO "CI: SSH key import skipped"
    elif [ -f "$HOME/.ssh/id_rsa" ]; then
      $VERBOSE_ECHO "SSH key already exists, skipping import"
    elif ! ${pkgs.doppler}/bin/doppler whoami &>/dev/null; then
      echo "WARNING: Doppler 未認証。'doppler login' 後に home-manager switch を再実行してください。"
    else
      $DRY_RUN_CMD bash -c "${pkgs.doppler}/bin/doppler secrets get SSH_PRIVATE_KEY --plain --project keys --config prd > \"$HOME/.ssh/id_rsa\""
      $DRY_RUN_CMD bash -c "${pkgs.doppler}/bin/doppler secrets get SSH_PUBLIC_KEY --plain --project keys --config prd > \"$HOME/.ssh/id_rsa.pub\""
      $DRY_RUN_CMD chmod 600 "$HOME/.ssh/id_rsa"
      $DRY_RUN_CMD chmod 644 "$HOME/.ssh/id_rsa.pub"
    fi
  '';
}
