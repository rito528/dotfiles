# プロファイルによる環境の使い分け（personal / work）

[`flake.nix`](../../flake.nix) の各マシン定義は `profile` に `"personal"` または `"work"` を持ち、
[`home.nix`](../../home.nix) の `profileImports` がこの値に応じて import するモジュールを切り替えます。

## 業務用マシンの設定を追加・変更する場合

- 差分は `if` 分岐ではなく `profileImports = { personal = [...]; work = [...]; }` というテーブルで
  列挙する方針です。個別の module 内で `profile` を見て分岐させることはしません。
- 実マシンの `profile` は [`flake.nix`](../../flake.nix) の `machines` / `darwinMachines` に定義します。
