# config/nvim/

`config/nvim/` は home-manager によって `~/.config/nvim` へ配備される Neovim 設定の正本です。

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

- 共通 grammar runtime は [modules/neovim.nix](/home/rito528/dotfiles/modules/neovim.nix:1) で `NVIM_TREESITTER_RUNTIME_GLOBAL` として配る
- project 固有 grammar runtime は `templates/*/flake.nix` の `shellHook` で `NVIM_TREESITTER_RUNTIME_PROJECT` として配る
- Neovim 側は [init.lua](/home/rito528/dotfiles/config/nvim/init.lua:1) で両方を `runtimepath` に追加する
- parser を追加・削除するときは、この判断軸と実際の template の責務が一致しているかを確認する

## 変更時の確認

- `.nix` を変えたら `nixfmt` を実行する
- Home Manager 側の変更は `home-manager build --flake .#testuser` で確認する
- template 側の変更は対応する devShell が評価できることを確認する
- Treesitter の配布先を変えた場合は、この README と関連ドキュメントも更新する
