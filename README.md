# dotfiles

[chezmoi](https://www.chezmoi.io/) を使用した Linux (Ubuntu / WSL) 環境向けの dotfiles リポジトリです。

## 概要

- **対象OS**: Linux (Ubuntu / Windows Subsystem for Linux)
- **ファイル管理**: [chezmoi](https://www.chezmoi.io/)
- **シェル**: Bash
- **エディタ**: Visual Studio Code

## ディレクトリ構成

```
dotfiles/
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions CI 定義
├── home/                   # chezmoi の Source State（ホームディレクトリへ展開される）
│   ├── .chezmoi.toml.tmpl  # chezmoi 設定テンプレート
│   ├── dot_bash_profile    # ~/.bash_profile
│   ├── dot_bashrc          # ~/.bashrc
│   ├── dot_gitconfig.tmpl  # ~/.gitconfig（テンプレート）
│   ├── dot_gitignore_global # ~/.gitignore_global
│   ├── dot_secretlintrc.json
│   ├── dot_claude/         # Claude Code 設定
│   │   ├── hooks/
│   │   ├── rules/
│   │   ├── settings.json
│   │   └── skills/
│   └── dot_config/
│       ├── Code/User/
│       │   └── settings.json  # VSCode 設定
│       └── git/hooks/
│           └── pre-commit
├── install/                # セットアップスクリプト（chezmoi の管理外）
│   ├── common/
│   │   ├── chezmoi.sh      # chezmoi のインストール
│   │   ├── nix.sh          # Nix パッケージマネージャーのインストール
│   │   ├── secretlint.sh   # secretlint のインストール
│   │   └── volta.sh        # Volta (Node.js バージョン管理) のインストール
│   └── ubuntu/
│       └── packages.sh     # apt パッケージのインストール
├── tests/
│   ├── Dockerfile          # テスト用 Docker イメージ定義
│   └── test.sh             # テストスクリプト
├── .chezmoiroot            # chezmoi のルートを `home/` に設定
├── renovate.json           # Renovate 依存関係自動更新設定
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
   - `git`, `curl`, `wget`, `gpg`, `jq`, `direnv`, `build-essential`
2. **Nix のインストール** (`install/common/nix.sh`)
   - Determinate Systems インストーラーを使用
3. **chezmoi のインストール** (`install/common/chezmoi.sh`)
4. **secretlint のインストール** (`install/common/secretlint.sh`)
5. **dotfiles の適用**
   - `chezmoi init` でリポジトリを Source として設定
   - `chezmoi apply` でホームディレクトリへ展開

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
| Claude Code | `dot_claude/` | `~/.claude/` |

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

## CI/CD

GitHub Actions により以下が自動実行されます：

- **Lint**: `shellcheck` によるシェルスクリプトの静的解析、`secretlint` によるシークレット漏洩チェック
- **Integration Test**: Docker コンテナ (Ubuntu) 上でセットアップスクリプトの動作を検証
