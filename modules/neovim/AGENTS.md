# modules/neovim/

Neovim の設定は [nixvim](https://github.com/nix-community/home-manager) を通じて宣言的に管理しています。
`default.nix` が各設定ファイルをインポートする入口です。

## ファイルの責務

設定は関心ごとにファイルを分けています。基本設定、プラグイン、LSP、言語固有設定（Scala）という分割になっています。

## check-keymaps.lua について

`check-keymaps.lua` は **Neovim の起動時には読み込まれません**。CI でのみ使用するヘッドレス実行スクリプトです。

- 役割: 全モードのキーマップを走査し、重複を検出して終了コードで報告する
- 実行タイミング: `integration-test.yaml` の「Check duplicate keymaps」ステップ
- 修正方法: 重複が検出された場合、キーマップを定義している `.nix` ファイルを確認して競合を解消する

新しいキーマップを追加した場合、CI がこのスクリプトで重複を検出します。ローカルで確認したい場合は integration-test.yaml の該当ステップを参考に同じコマンドを実行してください。

## Treesitter ランタイム

`default.nix` では `NVIM_TREESITTER_RUNTIME_GLOBAL` 環境変数を通じて共通の Treesitter パーサーランタイムを設定しています。テンプレートや外部設定ファイルとの共有に関する判断については、プロジェクトルートの AGENTS.md を参照してください。
