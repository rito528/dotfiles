{ ... }:
{
  # nix-darwin の現行 stateVersion。
  system.stateVersion = 6;

  # Determinate Nix installer 等、nix-darwin の外で nix 自体を管理する場合は false のままにする。
  nix.enable = false;

  # cleanup を "zap"/"uninstall" にすると宣言外のものを削除してしまうため、
  # 宣言していないものには触れないよう当面 "none" のままにする。
  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    casks = [
      # システム拡張の権限付与が必要なため nix パッケージではなく cask で導入する。
      "karabiner-elements"
    ];
  };
}
