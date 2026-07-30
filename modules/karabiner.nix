{ ... }:
{
  # karabiner.json 本体は Karabiner-Elements が実行時に書き換える状態ファイルのため管理しない。
  # ここでは Complex Modifications の候補ルールとして配置し、有効化は GUI 側の一度きりの操作に任せる。
  home.file.".config/karabiner/assets/complex_modifications/windows-style.json".source =
    ../config/karabiner/windows-style.json;
}
