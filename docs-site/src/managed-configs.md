# 管理対象と構成

## リポジトリ構成

- **`home.nix` / `modules/`**: Home Manager の設定と配備定義の正本。機能ごとに Nix モジュールを分割して管理しています。
- **`config/`**: home-manager が `~` 以下に配置する設定ファイルの正本。Claude Code 設定・AI スキル定義などを含みます。詳細は `config/AGENTS.md` と `config/README.md` を参照してください。
- **`.agents/skills/`**: リポジトリローカルの共有 AI スキル定義（Codex / Claude / Copilot などが参照）。
- **`.claude/`**: Claude Code ローカル設定。`skills` は `.agents/skills/` へのシンボリックリンクです。
- **`.githooks/`**: このリポジトリ専用の Git hooks の正本。
- **`install/`**: セットアップスクリプト群。`setup.sh` がエントリポイントです。
- **`templates/`**: プロジェクトごとの Nix 開発環境テンプレート。
- **`.github/workflows/`**: CI 定義。lint・ビルド検証・E2E テストなどを含みます。

## 管理対象の設定

| カテゴリ | ソースファイル | 展開先 |
|----------|---------------|--------|
| Shell | `modules/shell.nix` (programs.zsh) | 宣言的管理 (ファイルなし) |
| Git hooks | `.githooks/pre-commit` | このリポジトリの `.git/config` に `core.hooksPath=.githooks` を設定 |
| Codex | `modules/codex.nix` | `~/.codex/config.toml` と `~/.codex/rules/default.rules` |
| Claude Code | `config/claude/` | `~/.claude/` |
| Claude skills | `config/agents/skills/` | `~/.claude/skills` と `~/.agents/skills` へのシンボリックリンク |
| Shared AI skills | `.agents/skills/` | リポジトリローカルで各エージェントから参照 |

このリポジトリの Git hooks は `.githooks/` を正本とし、`./install/common/setup-local-hooks.sh` が repo-local の `core.hooksPath` を設定します。

シークレット検出には `gitleaks` を使用しています（このリポジトリでは `pre-commit` フックで実行）。GitHub Actions workflow の検証には `actionlint` を使用しています（同じく `pre-commit` フックでステージされた workflow ファイルに対して実行されます）。

ファイルの配置は `home.nix` の `home.file` で宣言的に管理されています。

`config/` 配下の運用ルールは `config/AGENTS.md`、配置方針や各サブディレクトリの意味は `config/README.md` と配下の README を参照してください。
