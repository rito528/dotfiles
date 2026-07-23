# セットアップ手順

## 前提条件

- Ubuntu / Debian 系 Linux または WSL
- `curl` がインストールされていること

## 1. リポジトリをクローン

```bash
git clone https://github.com/rito528/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 2. セットアップスクリプトを実行

```bash
./setup.sh
```

## 3. シェルを再起動

Nix をインストールした場合は、シェルを再起動するか以下を実行してください：

```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## 個別のスクリプトを実行する場合

各インストールスクリプトは単体でも実行可能です（冪等性あり）：

```bash
# Ubuntu パッケージのみインストール
./install/ubuntu/packages.sh

# Nix のみインストール
./install/common/nix.sh

# home-manager 設定の適用のみ
./install/common/home-manager.sh
```
