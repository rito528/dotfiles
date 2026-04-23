# AGENTS.md for Dotfiles

この文書は、この dotfiles リポジトリに対して AI Agent が安全に変更を加えるための運用ルールを定義するものです。
完全なディレクトリツリーや実装詳細の網羅はここでは管理しません。最新の構造や実装は、コード、各ディレクトリの README、生成物を正本としてください。

## 1. プロジェクト概要
- **目的**: Linux (Ubuntu / WSL) 環境におけるユーザー設定の管理とセットアップ自動化
- **コアツール**: [home-manager](https://github.com/nix-community/home-manager)
- **メインシェル**: zsh
- **CI/CD**: GitHub Actions
- **ターゲット OS**: Linux、特に Ubuntu および Windows Subsystem for Linux

## 2. 正本
- **Home Manager の設定と配備定義**: `home.nix`, `modules/`
- **配備される設定ファイル本体**: `config/`
- **repo ローカルの共有 AI skill**: `.agents/skills/`
- **home-manager 配備対象の AI skill / agent 設定**: `config/agents/`, `config/claude/`
- **Codex / Claude の配備定義**: `modules/codex.nix`, `modules/claude.nix`
- **セットアップ処理**: `install/`
- **CI と検証要件の実装**: `.github/workflows/`

## 3. 変更ガイド
- **Home Manager の挙動や有効化設定を変える**: `home.nix` と `modules/` を確認する
- **配備される設定ファイルの中身を変える**: `config/` を確認する
- **shell 関連を変える**: `modules/shell.nix` と対応する `config/` 配下を確認する
- **Git 設定を変える**: `modules/git.nix` を確認する
- **GPG / SSH 関連を変える**: `modules/gpg.nix`, `modules/ssh.nix` を確認する
- **Codex / Claude / AI Agent 設定を変える**: `modules/codex.nix`, `modules/claude.nix`, `.agents/skills/`, `config/agents/`, `config/claude/` のどれが正本かを確認する
- **Neovim 設定を変える**: `modules/neovim/` を確認する
- **セットアップ処理を変える**: `install/` を確認する。定常設定であれば Nix に寄せられないか先に検討する
- **npm/pnpm パッケージ管理を変える**: `modules/npm/default.nix` と `modules/npm/packages/` を確認する
- **カスタム package を変える**: `modules/packages/default.nix` と `modules/packages/` を確認する
- **カスタム script を追加・変更する**: `modules/scripts/default.nix` と `modules/scripts/` を確認する
- **CI を変える**: `.github/workflows/` を確認する

## 4. 変更ルール
1. **冪等性を保つ**:
    - `home-manager switch` は何度実行しても安全で、常に同じ結果になる必要があります。
    - セットアップスクリプトは、処理前に「すでにインストール済みか」「設定済みか」を必ず確認してください。
2. **宣言的な管理を優先する**:
    - 命令的なシェルスクリプトよりも、Nix による宣言的な設定を優先してください。
    - 環境ごとの微細な差異は、スクリプトの `if` 分岐ではなく、Nix の条件式で吸収してください。
3. **シークレットを分離する**:
    - 秘密鍵、API トークン、パスワードなどは絶対にリポジトリへコミットしないでください。
4. **CI / 非対話環境で動作するようにする**:
    - スクリプトは CI 環境でもエラーなく動作するように記述してください。
    - `sudo` がない環境や対話モードが使えない環境を考慮してください。
5. **追加・移動時は入口と参照先を確認する**:
    - 新しい module / script / skill / workflow を追加した場合は、対応する入口や参照先も確認してください。
    - rename / move を行う場合は、関連 README、参照リンク、CI 設定への影響を確認してください。
6. **AI Agent 設定の置き場所を混同しない**:
    - `.agents/skills/` は repo ローカルの共有定義です。
    - `config/agents/skills/` は home-manager 配備対象の定義です。
    - `config/claude/` は Claude Code の配備内容で、`modules/claude.nix` がその配置を管理します。

## 5. ドキュメント方針
- 完全なディレクトリツリーはこの文書に記載しない
- ファイル一覧やサブディレクトリ一覧を手書きで維持しない
- 頻繁に変わる詳細は、各ディレクトリ README または生成可能な一覧に委ねる
- この文書には、方針、責務、正本、変更判断基準のみを記載する

## 6. 検証要件
- **`.nix` ファイル変更後**: `nixfmt` を適用する
- **シェルスクリプト変更後**: `shellcheck` を通す
- **Home Manager に影響する変更後**: `home-manager build --flake .#testuser` を確認する
- **シークレット検出**: `gitleaks` を前提とする
- **ドキュメント参照先を変更した場合**: リンクや整合性チェックを通す

## 7. ディレクトリ別の参照先
- `config/` 配下の詳細な編集ルールは `config/AGENTS.md` を参照してください
- Claude 関連の詳細は `config/claude/AGENTS.md`, `config/claude/README.md` を参照してください
- agents 配下の詳細は `config/agents/AGENTS.md`, `config/agents/skills/README.md` を参照してください
- Neovim 設定の詳細は `modules/neovim/AGENTS.md` を参照してください
- 実装の全体像や詳細一覧が必要な場合は、まずコードと生成物を確認してください
