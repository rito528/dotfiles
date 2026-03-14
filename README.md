# dotfiles

[home-manager](https://github.com/nix-community/home-manager) を使用した Linux (Ubuntu / WSL) 環境向けの dotfiles リポジトリです。

## 概要

- **対象OS**: Linux (Ubuntu / Windows Subsystem for Linux)
- **ファイル管理**: [home-manager](https://github.com/nix-community/home-manager) (Nix Flake)
- **パッケージ管理**: [Nix](https://nixos.org/) + home-manager
- **シークレット管理**: [Doppler](https://www.doppler.com/) (GPG/SSH キーも含む)
- **シェル**: Bash
- **エディタ**: Visual Studio Code
- **追加ツール**: starship, direnv, gitleaks, difit (npm), claude-code

## ディレクトリ構成

```
dotfiles/
├── .github/workflows/        # GitHub Actions CI 定義
│   ├── ci.yml                # Lint・ビルド・Docker テスト
│   ├── nix-update-pr.yml     # Renovate 時のハッシュ自動更新
│   └── update-flake-lock.yml # 週次 flake.lock 更新
├── config/                   # home-manager が配置する設定ファイル群
│   ├── bashrc                # ~/.bashrc
│   ├── bash_profile          # ~/.bash_profile
│   ├── vscode/
│   │   └── settings.json     # VSCode 設定
│   ├── git/
│   │   └── hooks/
│   │       └── pre-commit    # Git pre-commit フック (gitleaks)
│   ├── claude/               # Claude Code 設定
│   │   ├── hooks/notify.sh   # WSL 向け Windows Toast 通知
│   │   ├── settings.json     # フック・プラグイン設定
│   │   └── skills/           # Claude Code スキル定義
│   └── secretlintrc.json     # secretlint 設定
├── nix/                      # Nix Flake + home-manager 設定
│   ├── flake.nix             # フレーク定義
│   ├── home.nix              # パッケージ・ファイル配置の宣言
│   └── modules/              # 機能別 Nix モジュール
│       ├── packages.nix      # コアパッケージ
│       ├── git.nix           # Git 設定・GPG 署名
│       ├── gpg.nix           # GPG/SSH キー管理 (Doppler)
│       ├── shell.nix         # Bash・starship・direnv
│       ├── claude.nix        # Claude Code 設定配置
│       ├── gitleaks.nix      # gitleaks
│       └── npm/              # npm/pnpm パッケージ管理
│           ├── default.nix
│           └── packages/     # パッケージ定義 (例: difit.nix)
├── install/                  # セットアップスクリプト
│   ├── common/               # OS 共通スクリプト
│   └── ubuntu/               # Ubuntu / Debian 系固有スクリプト
├── tests/                    # テスト用 Dockerfile・スクリプト
│   ├── Dockerfile
│   └── test.sh
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
| Shell | `config/bashrc` | `~/.bashrc` |
| Shell | `config/bash_profile` | `~/.bash_profile` |
| VSCode | `config/vscode/settings.json` | `~/.config/Code/User/settings.json` |
| Git hooks | `config/git/hooks/pre-commit` | `~/.config/git/hooks/pre-commit` |
| Claude Code | `config/claude/` | `~/.claude/` |
| secretlint | `config/secretlintrc.json` | `~/.secretlintrc.json` |

シークレット検出には `gitleaks` を使用しています（pre-commit フックで実行）。

ファイルの配置は `nix/home.nix` の `home.file` で宣言的に管理されています。

## home-manager の基本操作

```bash
# 設定を適用
home-manager switch --flake ./nix --impure

# ドライランで確認（実際には変更しない）
home-manager build --flake ./nix --impure

# 世代の一覧
home-manager generations
```
