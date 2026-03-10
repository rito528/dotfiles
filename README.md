# dotfiles

[chezmoi](https://www.chezmoi.io/) を使用した Linux (Ubuntu / WSL) 環境向けの dotfiles リポジトリです。

## 概要

- **対象OS**: Linux (Ubuntu / Windows Subsystem for Linux)
- **ファイル管理**: [chezmoi](https://www.chezmoi.io/)
- **パッケージ管理**: [Nix](https://nixos.org/) + [home-manager](https://github.com/nix-community/home-manager)
- **シェル**: Bash
- **エディタ**: Visual Studio Code

## ディレクトリ構成

```
dotfiles/
├── .github/workflows/      # GitHub Actions CI 定義
├── home/                   # chezmoi の Source State（ホームディレクトリへ展開される）
│   ├── dot_config/
│   │   ├── Code/User/      # VSCode 設定
│   │   ├── git/hooks/      # Git フック
│   │   └── home-manager/   # Nix Flake + home-manager 設定
│   └── dot_claude/         # Claude Code 設定
├── install/                # セットアップスクリプト（chezmoi の管理外）
│   ├── common/             # OS 共通スクリプト
│   └── ubuntu/             # Ubuntu / Debian 系固有スクリプト
├── tests/                  # テスト用 Dockerfile・スクリプト
├── .chezmoiroot            # chezmoi のルートを `home/` に設定
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

このスクリプトは以下を順番に実行します：

1. **apt パッケージのインストール** (`install/ubuntu/packages.sh`)
   - `git`, `curl`, `wget`, `gpg`, `build-essential`
2. **Nix のインストール** (`install/common/nix.sh`)
   - Determinate Systems インストーラーを使用
3. **chezmoi のインストール** (`install/common/chezmoi.sh`)
4. **dotfiles の適用**
   - `chezmoi init` でリポジトリを Source として設定
   - `chezmoi apply` でホームディレクトリへ展開
5. **home-manager の適用** (`install/common/home-manager.sh`)
   - `~/.config/home-manager/` の Nix Flake を使用してパッケージを管理

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

# chezmoi のみインストール
./install/common/chezmoi.sh

# Nix のみインストール
./install/common/nix.sh
```

## 管理対象の設定

| カテゴリ | ファイル | 展開先 |
|----------|----------|--------|
| Shell | `dot_bashrc` | `~/.bashrc` |
| Shell | `dot_bash_profile` | `~/.bash_profile` |
| Git | `dot_gitconfig.tmpl` | `~/.gitconfig` |
| Git | `dot_gitignore_global` | `~/.gitignore_global` |
| VSCode | `dot_config/Code/User/settings.json` | `~/.config/Code/User/settings.json` |
| Git hooks | `dot_config/git/hooks/pre-commit` | `~/.config/git/hooks/pre-commit` |
| home-manager | `dot_config/home-manager/` | `~/.config/home-manager/` |
| Claude Code | `dot_claude/` | `~/.claude/` |

### home-manager 管理パッケージ

以下のパッケージは apt ではなく home-manager (Nix) で管理されます：

- `jq`
- `direnv`
- `starship`

## chezmoi の基本操作

```bash
# 現在の差分を確認
chezmoi diff

# 変更を適用
chezmoi apply

# ドライランで確認（実際には変更しない）
chezmoi apply --dry-run

# ソースディレクトリを編集
chezmoi edit ~/.bashrc
```
