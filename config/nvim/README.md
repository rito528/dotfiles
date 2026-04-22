# config/nvim/

`config/nvim/` は Neovim runtime 追加ファイルの正本置き場です。

`programs.nixvim` が直接配備する設定に取り込むものと、Home Manager が `~/.config/nvim` へリンクするものが含まれます。

Neovim 本体の設定正本は `modules/neovim/` にあります。

## Treesitter の配置方針

このリポジトリでは Treesitter parser runtime を 2 層で管理します。

- `Home Manager`
  - どのプロジェクトでもほぼ確実に使う共通 grammar を配る
  - 例: `lua`, `markdown`, `markdown_inline`, `json`, `yaml`, `toml`
- `templates/*/flake.nix`
  - その template で主に使う言語だけを追加する
  - 例: `rust`, `sql`, `typescript`, `javascript`, `scala`, `hcl`

## 判断軸

- グローバル配備する:
  - dotfiles 自身でも頻繁に編集する
  - README や設定ファイルのように複数プロジェクトで横断的に使う
  - 常時有効でも責務がぶれにくい
- dev shell に閉じる:
  - ある template の主要実装言語である
  - 他の template では不要である
  - formatter / LSP / build tool もその shell に閉じている

迷った場合は、まず Home Manager に共通 grammar を置き、template 側には追加分だけを載せる。

## 実装ルール

- 共通 grammar runtime は [modules/neovim/default.nix](/home/rito528/dotfiles/modules/neovim/default.nix:1) で `NVIM_TREESITTER_RUNTIME_GLOBAL` として配る
- project 固有 grammar runtime は `templates/*/flake.nix` の `shellHook` で `NVIM_TREESITTER_RUNTIME_PROJECT` として配る
- Neovim 側は [modules/neovim/base.nix](/home/rito528/dotfiles/modules/neovim/base.nix:1) の `extraConfigLuaPre` で両方を `runtimepath` に追加する
- 言語固有の LSP 実行環境は、必要に応じて対応する `templates/*/flake.nix` の dev shell が供給する
- Scala は `templates/seichi-assist/flake.nix` の dev shell で `metals`, `coursier`, `bloop`, `sbt` を揃え、Neovim 側は `nvim-metals` でそれらを利用する
- parser を追加・削除するときは、この判断軸と実際の template の責務が一致しているかを確認する

## 変更時の確認

- `.nix` を変えたら `nixfmt` を実行する
- Home Manager 側の変更は `home-manager build --flake .#testuser` で確認する
- template 側の変更は対応する devShell が評価できることを確認する
- Scala の IDE 機能は `seichi-assist` dev shell 内で Neovim を起動した場合だけを保証する
- Metals 初回起動時は build import や build server 接続に少し時間がかかることがある
- Treesitter の配布先を変えた場合は、この README と関連ドキュメントも更新する
