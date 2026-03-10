# dotfiles

[home-manager](https://github.com/nix-community/home-manager) を使用した Linux (Ubuntu / WSL) 環境向けの dotfiles リポジトリです。

## 概要

- **対象OS**: Linux (Ubuntu / Windows Subsystem for Linux)
- **ファイル管理**: [home-manager](https://github.com/nix-community/home-manager) (Nix Flake)
- **パッケージ管理**: [Nix](https://nixos.org/) + home-manager
- **シークレット管理**: [Doppler](https://www.doppler.com/)
- **シェル**: Bash
- **エディタ**: Visual Studio Code

## ディレクトリ構成

```
dotfiles/
├── .github/workflows/      # GitHub Actions CI 定義
├── config/                 # home-manager が配置する設定ファイル群
│   ├── bashrc              # ~/.bashrc
│   ├── bash_profile        # ~/.bash_profile
│   ├── vscode/
│   │   └── settings.json   # VSCode 設定
│   ├── git/
│   │   └── hooks/
│   │       └── pre-commit  # Git pre-commit フック (secretlint)
│   ├── claude/             # Claude Code 設定
│   └── secretlintrc.json   # secretlint 設定
├── nix/                    # Nix Flake + home-manager 設定
│   ├── flake.nix           # フレーク定義
│   └── home.nix            # パッケージ・ファイル配置の宣言
├── install/                # セットアップスクリプト
│   ├── common/             # OS 共通スクリプト
│   └── ubuntu/             # Ubuntu / Debian 系固有スクリプト
├── tests/                  # テスト用 Dockerfile・スクリプト
└── setup.sh                # セットアップエントリポイント
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
