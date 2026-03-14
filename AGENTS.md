# AGENT.md for Dotfiles

このドキュメントは、この dotfiles リポジトリの運用ルール、技術選定、およびコーディング規約を定義するものです。
AI アシスタントは、コードの生成や変更の提案を行う際、以下のガイドラインに従ってください。

## 1. プロジェクト概要と技術スタック
- **目的**: Linux (Ubuntu / WSL) 環境におけるユーザー設定 (dotfiles) の管理とセットアップ自動化。
- **コアツール**: [home-manager](https://github.com/nix-community/home-manager) (ファイル管理・パッケージ管理)。
- **メインシェル**: Bash。zsh は使用しません。
- **メインエディタ**: Visual Studio Code (VSCode)。Vim/Emacs の設定よりも VSCode の設定管理を優先します。
- **CI/CD**: GitHub Actions (Pull Request / Push 時に検証を実行)。
- **ターゲットOS**: Linux (特に Ubuntu および Windows Subsystem for Linux)。

## 2. 基本原則 (Key Principles)
1.  **冪等性 (Idempotency) の徹底**:
    - `home-manager switch` は何度実行しても安全で、常に同じ結果になる必要があります。
    - セットアップスクリプトは、処理を行う前に「すでにインストール済みか」「設定済みか」を必ずチェックしてください。
2.  **宣言的な管理**:
    - 命令的なシェルスクリプトよりも、`nix/home.nix` での宣言的な設定を優先します。
    - 環境ごとの微細な差異は、スクリプトの `if` 分岐ではなく、Nix の条件式を使用して吸収してください。
3.  **シークレットの分離**:
    - **重要**: 秘密鍵、APIトークン、パスワードなどは**絶対にリポジトリにコミットしないでください**。
4.  **テスト容易性**:
    - スクリプトは CI 環境 (Docker コンテナ) でもエラーなく動作するように記述してください（例: `sudo` がない環境や、対話モードが使えない環境への配慮）。

## 3. ディレクトリ構造 (Directory Structure)

- **ディレクトリ構成詳細**:
    - **`nix/`**: home-manager の Nix フレーク設定。
        - `flake.nix`: フレーク定義。
        - `home.nix`: ホームディレクトリの設定・パッケージ管理。ここで `home.file` を使って `config/` 以下のファイルを配置します。
        - `modules/`: 機能別に分割された Nix モジュール。
            - `packages.nix`: コアパッケージ (jq, direnv, starship, nixfmt, doppler, gh, ripgrep, claude-code)
            - `git.nix`: Git 設定・GPG 署名・gh 認証情報ヘルパー
            - `gpg.nix`: GPG/SSH キーを Doppler から取得・設定 (CI 時はスキップ)
            - `shell.nix`: Bash・starship・direnv・cargo・pnpm パス設定
            - `claude.nix`: `config/claude/` を `~/.claude/` に配置
            - `gitleaks.nix`: gitleaks パッケージ
            - `npm/default.nix` + `npm/packages/`: npm/pnpm パッケージの動的管理 (例: difit.nix)
    - **`config/`**: home-manager が配置する生ファイル群。
        - `bashrc`, `bash_profile`: シェル設定。
        - `vscode/settings.json`: VSCode 設定。
        - `git/hooks/pre-commit`: Git フック (gitleaks によるシークレット検出)。
        - `secretlintrc.json`: secretlint 設定。
        - `claude/`: Claude Code 設定。
            - `hooks/notify.sh`: WSL 向け Windows Toast 通知スクリプト。
            - `settings.json`: フック・プラグイン設定。
            - `skills/`: Claude Code スキル定義 (SKILL.md)。
    - **`install/`**: (Bootstrap & Setup) セットアップ用スクリプト置き場。
        - `common/`: ディストリビューションに依存しない共通処理。
        - `ubuntu/`: Ubuntu / Debian 系固有の処理（apt パッケージのインストールなど）。
    - **`tests/`**: (Validation)
        - `Dockerfile`: 検証環境の定義。
        - テスト実行用のスクリプト。

## 3.1. Claude Code スキルについて

`config/claude/skills/` に Claude Code スキル定義 (SKILL.md) を管理しています。
新規スキル追加時は `add-npm-package` スキルの手順に準じてください。

## 3.2. Renovate / CI ワークフローについて

- `.github/workflows/ci.yml`: Lint・ビルド・Docker テストを実行。
- `.github/workflows/nix-update-pr.yml`: Renovate が npm パッケージバージョンを上げた際、pnpm ハッシュを自動再計算してコミット。
- `.github/workflows/update-flake-lock.yml`: 週次で `flake.lock` を更新する PR を自動作成。

## 4. CI/CD と検証ガイドライン
- **Lint**:
    - すべてのシェルスクリプトは `shellcheck` をパスすること。
    - すべての `.nix` ファイルは `nixfmt` でフォーマットされていること。コード変更後は `nixfmt <file>` を実行してフォーマットを適用してください。
- **Integration Test**:
    - CI パイプラインでは `home-manager build --flake ./nix` を実行し、ビルドエラーがないかを確認する。
    - `tests/Dockerfile` (Ubuntu ベース) を使用し、クリーンな環境に対して実際のセットアップスクリプトが成功するかを検証する。
    - `Dockerfile` を変更した場合は、`docker build` が成功することを確認すること。

## 4.1. 取り込み要件 (Merge Requirements)
PR をマージする前に、以下がすべてパスしていることを確認してください：
1. **nixfmt**: すべての `.nix` ファイルが `nixfmt` でフォーマット済みであること。
2. **Docker build**: `tests/Dockerfile` のビルドが成功すること (`docker build -f tests/Dockerfile .`)。
3. **shellcheck**: すべてのシェルスクリプトが `shellcheck` をパスしていること。
4. **home-manager build**: `home-manager build --flake ./nix` がエラーなく完了すること。

シークレット検出には `secretlint` ではなく `gitleaks` を使用しています（pre-commit フックおよび CI で実行）。

## 5. 管理対象コンポーネント
このリポジトリで管理すべき主な対象：
- **VSCode**: `settings.json`, `keybindings.json`, および推奨拡張機能リスト。
- **Shell**: `.bashrc`, `.bash_profile`
- **Git**: `.gitconfig` (`programs.git` で管理), `.gitignore` (グローバル設定)
- **WSL固有**: `wsl.conf` 等が必要な場合は、OS 判定ロジックを用いて管理する。

変更を提案する際は、VSCode の設定を最優先とし、Nix の条件式などを適切に使用してください。
