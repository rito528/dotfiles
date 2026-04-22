---
name: neovim-treesitter-runtime
description: dotfiles の Neovim Treesitter parser runtime を Home Manager と templates のどちらに置くべきか判断し、必要な Nix とドキュメントを更新するためのスキル
---

# neovim-treesitter-runtime

このリポジトリで Treesitter parser runtime の配置先を決めるときに使う。

## 判断ルール

- `modules/neovim.nix` に置く:
  - dotfiles 自身でも頻繁に使う
  - 設定ファイルやドキュメントのように複数プロジェクトで横断的に編集する
  - 常時グローバル配備でも責務がぶれにくい
- `templates/*/flake.nix` に置く:
  - その template の主要実装言語である
  - 他の template では不要である
  - LSP / formatter / build tool もその shell に閉じている

基本は「共通 grammar は Home Manager、追加 grammar は template shell」。

## 実装手順

1. 追加・変更したい grammar が共通か project 固有かを判定する
2. 共通なら `modules/neovim.nix` の `commonTreesitterRuntime` を更新する
3. project 固有なら対象 `templates/*/flake.nix` の `treesitterRuntime` を更新する
4. `config/nvim/init.lua` が `NVIM_TREESITTER_RUNTIME_GLOBAL` と `NVIM_TREESITTER_RUNTIME_PROJECT` を読む前提を壊していないか確認する
5. 判断軸に影響する変更なら `config/nvim/README.md` と必要に応じてルート `README.md` を更新する
6. `.nix` を変更したら `nixfmt` を実行する

## 注意点

- template 側に共通 grammar を重複定義しない
- Home Manager 側に project 専用 grammar を増やしすぎない
- Treesitter runtime の配布先を変えるときは、実装だけでなく判断軸の文書も同時に更新する
