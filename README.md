# dotfiles

[home-manager](https://github.com/nix-community/home-manager) を使用した Linux (Ubuntu / WSL) 環境向けの dotfiles リポジトリです。

## 概要

- **対象OS**: Linux (Ubuntu / Windows Subsystem for Linux)
- **ファイル管理**: [home-manager](https://github.com/nix-community/home-manager) (Nix Flake)
- **パッケージ管理**: [Nix](https://nixos.org/) + home-manager
- **シークレット管理**: [Doppler](https://www.doppler.com/) (GPG/SSH キーも含む)
- **シェル**: zsh

## ディレクトリ構成

```
dotfiles/
├── .github/workflows/        # GitHub Actions CI 定義
│   ├── lint.yaml             # shellcheck・nixfmt Lint
│   ├── integration-test.yaml # Cachix を使った home-manager ビルド検証
│   ├── nix.yaml              # Nix flake check
│   ├── devshell.yaml         # templates/ 配下の devShell ビルド検証
│   ├── nix-update-pr.yaml    # Renovate 時のハッシュ自動更新
│   ├── update-flake-lock.yaml # 週次 flake.lock 更新
│   ├── e2e-setup-test.yaml   # セットアップ E2E テスト
│   └── renovate.yaml         # Renovate 設定
├── .agents/                  # エージェント横断のローカル AI 定義
│   └── skills/               # Codex / Claude / Copilot 共有スキル
├── .claude/                  # Claude Code ローカル設定
│   ├── agents/               # Claude 用カスタムエージェント
│   └── skills -> ../.agents/skills # 共有スキルへの互換リンク
├── config/                   # home-manager が配置する設定ファイル群
│   ├── agents/
│   │   └── skills/           # home-manager 配備用 AI スキル定義
│   ├── AGENTS.md             # config/ 配下専用の運用ルール
│   ├── claude/               # Claude Code 設定
│   │   ├── hooks/notify.sh   # WSL 向け Windows Toast 通知
│   │   ├── settings.json     # フック・プラグイン設定
│   └── README.md             # config/ 全体の説明
├── .githooks/                # このリポジトリ専用の Git hooks
├── flake.nix                 # フレーク定義
├── flake.lock                # フレークロックファイル
├── home.nix                  # パッケージ・ファイル配置の宣言
├── modules/                  # 機能別 Nix モジュール
│   ├── packages.nix          # コアパッケージ
│   ├── git.nix               # Git 設定・GPG 署名
│   ├── gpg.nix               # GPG/SSH キー管理 (Doppler)
│   ├── shell.nix             # zsh・starship・direnv
│   ├── ssh.nix               # SSH 設定
│   ├── codex.nix             # Codex CLI 設定配置
│   ├── claude.nix            # Claude Code 設定配置
│   ├── gitleaks.nix          # gitleaks
│   ├── npm/                  # npm/pnpm パッケージ管理
│   │   ├── default.nix
│   │   └── packages/         # パッケージ定義 (例: difit.nix)
│   ├── packages/             # カスタムパッケージ (actrun, git-wt など)
│   └── scripts/              # カスタムスクリプト
├── templates/                # Nix 開発環境テンプレート
├── install/                  # セットアップスクリプト
│   ├── common/               # OS 共通スクリプト (nix.sh, home-manager.sh, chsh-zsh.sh, setup-local-hooks.sh)
│   └── ubuntu/               # Ubuntu / Debian 系固有スクリプト
└── setup.sh                  # セットアップエントリポイント
```

## セットアップ手順

### 前提条件

- Ubuntu / Debian 系 Linux または WSL
- `curl` がインストールされていること

### 1. リポジトリをクローン

```bash
git clone https://github.com/rito528/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. セットアップスクリプトを実行

```bash
./setup.sh
```

### 3. シェルを再起動

Nix をインストールした場合は、シェルを再起動するか以下を実行してください：

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 個別のスクリプトを実行する場合

各インストールスクリプトは単体でも実行可能です（冪等性あり）：

```bash
# Ubuntu パッケージのみインストール
./install/ubuntu/packages.sh

# Nix のみインストール
./install/common/nix.sh

# home-manager 設定の適用のみ
./install/common/home-manager.sh
```

## 管理対象の設定

| カテゴリ | ソースファイル | 展開先 |
|----------|---------------|--------|
| Shell | `modules/shell.nix` (programs.zsh) | 宣言的管理 (ファイルなし) |
| Git hooks | `.githooks/pre-commit` | このリポジトリの `.git/config` に `core.hooksPath=.githooks` を設定 |
| Codex | `modules/codex.nix` | `~/.codex/config.toml` と `~/.codex/rules/default.rules` |
| Claude Code | `config/claude/` | `~/.claude/` |
| Claude skills | `config/agents/skills/` | `~/.claude/skills` と `~/.agents/skills` へのシンボリックリンク |
| Shared AI skills | `.agents/skills/` | リポジトリローカルで各エージェントから参照 |

このリポジトリの Git hooks は `.githooks/` を正本とし、`./install/common/setup-local-hooks.sh` が repo-local の `core.hooksPath` を設定します。

シークレット検出には `gitleaks` を使用しています（このリポジトリでは `pre-commit` フックで実行）。

ファイルの配置は `home.nix` の `home.file` で宣言的に管理されています。

`config/` 配下の運用ルールは `config/AGENTS.md`、配置方針や各サブディレクトリの意味は `config/README.md` と配下の README を参照してください。

## home-manager の基本操作

```bash
# 設定を適用
home-manager switch --flake .

# ドライランで確認（実際には変更しない）
home-manager build --flake .

# 世代の一覧
home-manager generations
```

## 開発環境テンプレート

プロジェクトごとに独立した Nix 開発環境を提供するテンプレートを管理しています（`templates/` 参照）。

Neovim の Treesitter parser runtime は 2 層で管理します。

- Home Manager:
  - `lua`, `markdown`, `markdown_inline`, `json`, `yaml`, `toml` のような共通 grammar を配る
- template devShell:
  - `rust`, `sql`, `typescript`, `javascript`, `scala`, `hcl` のような project 固有 grammar を追加する

判断軸と実装ルールの詳細は `config/nvim/README.md` を参照してください。

Neovim 本体の設定正本は `modules/neovim/` にあり、`config/nvim/` には runtime 追加ファイルだけを置きます。

### 自分のプロジェクトで使う場合

```bash
# プロジェクトディレクトリで初期化（例）
nix flake init -t github:rito528/dotfiles#seichi-infra
```

### direnv との連携

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

### nix-init-env コマンド

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
