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

## macOS (nix-darwin) の場合

現状 [`setup.sh`](../../setup.sh) は Ubuntu/WSL 専用です。macOS では [Determinate Nix](https://determinate.systems/nix-installer/) 等で Nix 本体を別途導入したうえで、nix-darwin を直接使います。

```bash
git clone https://github.com/rito528/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 初回のみ: nix-darwin をブートストラップする
sudo nix run nix-darwin -- switch --flake .#<エントリ名>

# 2回目以降
darwin-rebuild switch --flake .#<エントリ名>
```

`<エントリ名>` は [`flake.nix`](../../flake.nix) の `darwinMachines` に定義したキーです。新しい Mac を追加する場合は、ここに実マシンのエントリを追加してください。

`modules/darwin/default.nix` で `homebrew.enable = true` にしているため、Homebrew(未導入なら要インストール)経由で `karabiner-elements` などの cask も導入されます。

### Karabiner-Elements の初期設定

[`config/karabiner/`](../../config/karabiner/) のキーリマップルールは配置されるだけで自動有効化はされないため、初回のみ以下を行ってください。

1. 初回起動時に表示される入力監視の権限許可を許可する
2. Karabiner-Elements の「Complex Modifications」タブから「Add rule」を行い、配置されたルールを有効化する

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
