# セットアップ手順

## 前提条件

- Ubuntu / Debian 系 Linux または WSL
- `curl` がインストールされていること
- [Doppler CLI](https://docs.doppler.com/docs/install-cli) がインストール済みで `doppler login` によるログインが完了していること（個人アカウントのブラウザ認証のみで完結します）
  - CA証明書・GPG鍵・SSH鍵は Doppler(project `keys`, config `prd`)から自動取得されます。未ログインのまま進めると、これらの手順は警告を出して silently スキップされ、鍵なしの状態でセットアップが完了してしまいます。

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

## 日常操作

セットアップ後、設定を変更した際は以下のコマンドで反映・確認します。

```bash
# 設定を適用
home-manager switch --flake .

# ドライランで確認（実際には変更しない）
home-manager build --flake .

# 世代の一覧
home-manager generations
```
