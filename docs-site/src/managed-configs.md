# 管理対象と構成

具体的なディレクトリ構成やファイル一覧は変更頻度が高く、この文書と二重管理すると必ず乖離します。
最新の構造は [`CLAUDE.md`](../../CLAUDE.md) と各ディレクトリの README・AGENTS.md を正本としてください。
ここには、コードを読むだけでは分かりにくい設計判断だけを残します。

## 設計判断

- **home-manager 配備対象とリポジトリローカルの分離**: [`config/agents/skills/`](../../config/agents/skills/) は home-manager が `~/.claude/skills` などへ配備する定義、[`.agents/skills/`](../../.agents/skills/) はリポジトリローカルで各エージェントが直接参照する共有定義です。両者は置き場所が似ているため混同しやすく、[`config/AGENTS.md`](../../config/AGENTS.md) で明確に区別しています。
- **Git hooks は home-manager 管理外**: このリポジトリの Git hooks は [`.githooks/`](../../.githooks/) を正本とし、home-manager では配布せず [`install/common/setup-local-hooks.sh`](../../install/common/setup-local-hooks.sh) が repo-local の `core.hooksPath` を設定します。ユーザー環境全体ではなく、このリポジトリ専用のフックだからです。
- **シークレット検出と CI 検証は pre-commit フックで実行**: `gitleaks`(シークレット検出)と `actionlint`(ステージされた workflow ファイルの検証)を `pre-commit` フックで実行しています。
- **`profile`(personal/work)は配線済みの未使用フィールド**: [`flake.nix`](../../flake.nix) の各マシン定義は `profile` に `"personal"` または `"work"` を持ちますが、現時点ではどの `modules/` も参照していません。将来 work profile 向けの分岐を追加する予定のための先行配線です。新しいマシンを追加する際も、この値だけで動作が変わることはまだありません。

詳細な配置ルールは [`config/AGENTS.md`](../../config/AGENTS.md) と [`config/README.md`](../../config/README.md) を参照してください。
