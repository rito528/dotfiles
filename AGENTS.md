# AGENT.md for Dotfiles

このドキュメントは、この dotfiles リポジトリの運用ルール、技術選定、およびコーディング規約を定義するものです。
AI アシスタントは、コードの生成や変更の提案を行う際、以下のガイドラインに従ってください。

## 1. プロジェクト概要と技術スタック
- **目的**: Linux (Ubuntu / WSL) 環境におけるユーザー設定 (dotfiles) の管理とセットアップ自動化。
- **コアツール**: [home-manager](https://github.com/nix-community/home-manager) (ファイル管理・パッケージ管理)
- **メインシェル**: zsh
- **CI/CD**: GitHub Actions
- **ターゲットOS**: Linux (特に Ubuntu および Windows Subsystem for Linux)

## 2. 基本原則
1.  **冪等性の徹底**:
    - `home-manager switch` は何度実行しても安全で、常に同じ結果になる必要があります。
    - セットアップスクリプトは、処理を行う前に「すでにインストール済みか」「設定済みか」を必ずチェックしてください。
2.  **宣言的な管理**:
    - 命令的なシェルスクリプトよりも、`nix/home.nix` での宣言的な設定を優先します。
    - 環境ごとの微細な差異は、スクリプトの `if` 分岐ではなく、Nix の条件式を使用して吸収してください。
3.  **シークレットの分離**:
    - **重要**: 秘密鍵、APIトークン、パスワードなどは**絶対にリポジトリにコミットしないでください**。
4.  **テスト容易性**:
    - スクリプトは CI 環境でもエラーなく動作するように記述してください（例: `sudo` がない環境や、対話モードが使えない環境への配慮）。

## 3. ディレクトリ構造 (Directory Structure)

- **ディレクトリ構成詳細**:
    - **`nix/`**: home-manager の Nix フレーク設定。
        - `flake.nix`: フレーク定義。
        - `home.nix`: ホームディレクトリの設定・パッケージ管理。ここで `home.file` を使って `config/` 以下のファイルを配置します。
        - `modules/`: 機能別に分割された Nix モジュール。
            - `packages.nix`: コアパッケージ
            - `git.nix`: Git 設定・GPG 署名・gh 認証情報ヘルパー
            - `gpg.nix`: GPG/SSH キーを Doppler から取得・設定 (CI 時はスキップ)
            - `ssh.nix`: SSH キー管理モジュール
            - `shell.nix`: zsh・starship・direnv・cargo・pnpm パス設定
            - `claude.nix`: `config/claude/` を `~/.claude/` に配置
            - `gitleaks.nix`: gitleaks パッケージ
            - `npm/default.nix` + `npm/packages/`: npm/pnpm パッケージの動的管理 
            - `packages/default.nix` + `packages/`: カスタムパッケージの動的管理 
            - `scripts/default.nix` + `scripts/`: カスタムシェルスクリプト管理
    - **`config/`**: home-manager が配置する生ファイル群。
        - `zshrc`, `zprofile`: シェル設定。
        - `git/hooks/pre-commit`: Git フック (gitleaks によるシークレット検出)。
        - `claude/`: Claude Code 設定。
            - `hooks/notify.sh`: WSL 向け Windows Toast 通知スクリプト。
            - `settings.json`: フック・プラグイン設定。
            - `skills/`: リポジトリ管理の Claude Code スキル。
    - **`.claude/`**: ローカル開発用 Claude Code 設定。
        - `agents/`: カスタムエージェント定義。
        - `skills/`: ローカルスキル定義。
        - `worktrees/`: ワークツリー管理。
    - **`install/`**: (Bootstrap & Setup) セットアップ用スクリプト置き場。
        - `setup.sh`: エントリーポイント。OS を検出して以下のスクリプトを順に呼び出す。
        - `common/`: ディストリビューションに依存しない共通処理。
        - `ubuntu/`: Ubuntu / Debian 系固有の処理。
    - **`nix/templates/`**: 開発環境テンプレート。
    - **`.githooks/`**: ローカル git フック。
        - `install/common/setup-local-hooks.sh` で登録セットアップされている。

## 3.1. Claude Code スキルについて

Claude Code スキル定義は 2 か所に分かれています：
- **`config/claude/skills/`**: home-manager によって `~/.claude/skills/` に配置されるスキル (create-pr, ensure-branch, git-commit)。
- **`.claude/skills/`**: リポジトリローカルのスキル (add-npm-package, add-script)。

## 3.2. Renovate / CI ワークフローについて

- `.github/workflows/lint.yaml`: shellcheck・nixfmt Lint を実行。
- `.github/workflows/integration-test.yaml`: Cachix を使った `home-manager build` によるビルド検証を実行。
- `.github/workflows/nix.yaml`: `nix flake check` を実行。
- `.github/workflows/nix-update-pr.yaml`: Renovate が npm パッケージバージョンを上げた際、pnpm ハッシュを自動再計算してコミット。
- `.github/workflows/update-flake-lock.yaml`: 週次で `flake.lock` を更新する PR を自動作成。
- `.github/workflows/renovate.yaml`: Renovate ボット設定。
- `.github/workflows/e2e-setup-test.yaml`: ubuntu-24.04 でのセットアップ E2E テスト。

## 4. CI/CD と検証ガイドライン
- **Lint**:
    - すべてのシェルスクリプトは `shellcheck` をパスすること。
    - すべての `.nix` ファイルは `nixfmt` でフォーマットされていること。コード変更後は `nixfmt <file>` を実行してフォーマットを適用してください。
- **Integration Test**:
    - CI パイプラインでは GitHub Actions + Cachix を使い、`home-manager build --flake ./nix#testuser` を実行してビルドエラーがないかを確認する。

## 4.1. 取り込み要件 (Merge Requirements)
PR をマージする前に、以下がすべてパスしていることを確認してください：
1. **nixfmt**: すべての `.nix` ファイルが `nixfmt` でフォーマット済みであること。
2. **shellcheck**: すべてのシェルスクリプトが `shellcheck` をパスしていること。
3. **home-manager build**: `home-manager build --flake ./nix#testuser` がエラーなく完了すること（CI で Cachix を使用）。
4. **gitleaks**: シークレット検出は `gitleaks` で実行（pre-commit フックおよび CI で実行）。

## 5. 管理対象コンポーネント
このリポジトリで管理すべき主な対象：
- **Shell**: `.zshrc`, `.zprofile`
- **Git**: `.gitconfig` (`programs.git` で管理), `.gitignore` (グローバル設定)
- **WSL固有**: `wsl.conf` 等が必要な場合は、OS 判定ロジックを用いて管理する。
