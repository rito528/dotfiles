# AGENT.md for Dotfiles

このドキュメントは、この dotfiles リポジトリの運用ルール、技術選定、およびコーディング規約を定義するものです。
AI アシスタントは、コードの生成や変更の提案を行う際、以下のガイドラインに従ってください。

## 1. プロジェクト概要と技術スタック
- **目的**: Linux (Ubuntu / WSL) 環境におけるユーザー設定 (dotfiles) の管理とセットアップ自動化。
- **コアツール**: [chezmoi](https://www.chezmoi.io/) (ファイル管理・テンプレート適用)。
- **メインシェル**: Bash。zsh は使用しません。
- **メインエディタ**: Visual Studio Code (VSCode)。Vim/Emacs の設定よりも VSCode の設定管理を優先します。
- **CI/CD**: GitHub Actions (Pull Request / Push 時に検証を実行)。
- **ターゲットOS**: Linux (特に Ubuntu および Windows Subsystem for Linux)。

## 2. 基本原則 (Key Principles)
1.  **冪等性 (Idempotency) の徹底**:
    - `chezmoi apply` は何度実行しても安全で、常に同じ結果になる必要があります。
    - セットアップスクリプトは、処理を行う前に「すでにインストール済みか」「設定済みか」を必ずチェックしてください。
2.  **宣言的な管理**:
    - 命令的なシェルスクリプトよりも、設定ファイル自体を配置することを優先します。
    - 環境ごとの微細な差異は、スクリプトの `if` 分岐ではなく、chezmoi のテンプレート機能 (`.tmpl`) を使用して吸収してください。
3.  **シークレットの分離**:
    - **重要**: 秘密鍵、APIトークン、パスワードなどは**絶対にリポジトリにコミットしないでください**。
4.  **テスト容易性**:
    - スクリプトは CI 環境 (Docker コンテナ) でもエラーなく動作するように記述してください（例: `sudo` がない環境や、対話モードが使えない環境への配慮）。

## 3. ディレクトリ構造 (Directory Structure)
このリポジトリは、設定ファイル（Source State）と運用スクリプトを明確に分離するため、カスタムルート設定を使用します。

- **ルート設定**:
    - リポジトリルートに `.chezmoiroot` ファイルを配置し、内容に `home` と記述しています。
    - これにより、chezmoi は `home/` ディレクトリ配下のみをホームディレクトリへの適用対象として扱います。

- **ディレクトリ構成詳細**:
    - **`home/`**: (Source State) ホームディレクトリに配置されるドットファイル群。
        - ここにある `dot_bashrc` が `~/.bashrc` に展開されます。
        - VSCode の設定ファイル (`settings.json` 等) もこの配下で適切なパス (`dot_config/Code/...`) に配置します。
    - **`install/`**: (Bootstrap & Setup) セットアップ用スクリプト置き場。
        - `common/`: ディストリビューションに依存しない共通処理（npm パッケージのインストールなど）。
        - `ubuntu/`: Ubuntu / Debian 系固有の処理（apt パッケージのインストールなど）。
        - ※ このディレクトリは `chezmoi apply` でホームディレクトリにはコピーされません。リポジトリパスを参照して実行されます。
    - **`tests/`**: (Validation)
        - `Dockerfile`: 検証環境の定義。
        - テスト実行用のスクリプト。

## 4. CI/CD と検証ガイドライン
- **Lint**:
    - すべてのシェルスクリプトは `shellcheck` をパスすること。
- **Integration Test**:
    - CI パイプラインでは `chezmoi apply --dry-run` を実行し、テンプレート展開エラーがないかを確認する。
    - `tests/Dockerfile` (Ubuntu ベース) を使用し、クリーンな環境に対して実際のセットアップスクリプトが成功するかを検証する。

## 5. 管理対象コンポーネント
このリポジトリで管理すべき主な対象：
- **VSCode**: `settings.json`, `keybindings.json`, および推奨拡張機能リスト。
    - OS (Linux/WSL) によるパスの違いは chezmoi のテンプレートで吸収する。
- **Shell**: `.bashrc`, `.bash_profile`
- **Git**: `.gitconfig` (ユーザー設定、エイリアス), `.gitignore` (グローバル設定)
- **WSL固有**: `wsl.conf` 等が必要な場合は、OS 判定ロジックを用いて管理する。

変更を提案する際は、VSCode の設定を最優先とし、`{{ if eq .chezmoi.os "linux" }}` などの条件分岐を適切に使用してください。
