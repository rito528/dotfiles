{ ... }:
{
  # nix-darwin の現行 stateVersion。
  system.stateVersion = 6;

  # Determinate Nix installer 等、nix-darwin の外で nix 自体を管理する場合は false のままにする。
  nix.enable = false;

  # まだ使わない。使う際は enable = true にして taps/brews/casks を追加する。
  # cleanup を "zap"/"uninstall" にすると宣言外のものを削除してしまうため、
  # 宣言していないものには触れないよう当面 "none" のままにする。
  homebrew = {
    enable = false;
    onActivation.cleanup = "none";
  };
}
