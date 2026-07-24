# 開発環境テンプレート

プロジェクトごとに独立した Nix 開発環境を提供するテンプレートを管理しています（[`templates/`](../../templates/) 参照）。

Neovim の Treesitter parser runtime は 2 層で管理します。

- Home Manager:
  - `lua`, `markdown`, `markdown_inline`, `json`, `yaml`, `toml` のような共通 grammar を配る
- template devShell:
  - `rust`, `sql`, `typescript`, `javascript`, `scala`, `hcl` のような project 固有 grammar を追加する

Neovim 本体の設定正本は [`modules/neovim/`](../../modules/neovim/) にあります。

## 自分のプロジェクトで使う場合

```bash
# プロジェクトディレクトリで初期化（例）
nix flake init -t github:rito528/dotfiles#seichi-infra
```

## direnv との連携

プロジェクトディレクトリに `.envrc` を作成することで、ディレクトリに入ると自動的に開発環境が有効になります：

```bash
# テンプレートで初期化したプロジェクトの場合
echo "use flake" > .envrc
direnv allow

# dotfiles のテンプレートを直接参照する場合
echo "use flake 'github:rito528/dotfiles?dir=templates/rust'" > .envrc
direnv allow
```

> `.envrc` はプロジェクト固有の設定のため、global gitignore に追加することを推奨します。

## nix-init-env コマンド

`nix-init-env` は、プロジェクトディレクトリに `.envrc` を対話的に生成するコマンドです。
このリポジトリで管理されているテンプレート一覧を取得し、選択した内容で `.envrc` を作成します。

```bash
# プロジェクトディレクトリで実行
nix-init-env
```

- fzf がインストールされている場合はインタラクティブに選択できます
- `local` を選択すると `use flake`（ローカル flake 参照）が生成されます
- それ以外を選択すると `use flake 'github:rito528/dotfiles#<template>'` が生成されます
- `.envrc` が既に存在する場合は上書き確認を行います
- 生成後、`direnv allow` を実行するか確認します
