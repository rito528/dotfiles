# 管理対象と構成

具体的なディレクトリ構成やファイル一覧は変更頻度が高く、この文書と二重管理すると必ず乖離します。
最新の構造は [`CLAUDE.md`](../../CLAUDE.md) と各ディレクトリの README・AGENTS.md を正本としてください。
ここには、コードを読むだけでは分かりにくい設計判断だけを残します。

## 設計判断

- **home-manager 配備対象とリポジトリローカルの分離**: [`config/agents/skills/`](../../config/agents/skills/) は home-manager が `~/.claude/skills` などへ配備する定義、[`.agents/skills/`](../../.agents/skills/) はリポジトリローカルで各エージェントが直接参照する共有定義です。両者は置き場所が似ているため混同しやすく、[`config/AGENTS.md`](../../config/AGENTS.md) で明確に区別しています。
- **Git hooks は home-manager 管理外**: このリポジトリの Git hooks は [`.githooks/`](../../.githooks/) を正本とし、home-manager では配布せず [`install/common/setup-local-hooks.sh`](../../install/common/setup-local-hooks.sh) が repo-local の `core.hooksPath` を設定します。ユーザー環境全体ではなく、このリポジトリ専用のフックだからです。
- **シークレット検出と CI 検証は pre-commit フックで実行**: `gitleaks`(シークレット検出)と `actionlint`(ステージされた workflow ファイルの検証)を `pre-commit` フックで実行しています。
- **`profile`(personal/work)による導入物の分岐**: [`flake.nix`](../../flake.nix) の各マシン定義は `profile` に `"personal"` または `"work"` を持ち、[`home.nix`](../../home.nix) がこの値に応じて import するモジュールを切り替えます。私物 PC で使うツールを業務 PC にそのまま入れるとシャドー IT になりうるため、`profile = "work"` では AI Agent CLI を最小限(claude-code のみ)に絞り、個人プロジェクト連携モジュール([`grafana-mcp.nix`](../../modules/grafana-mcp.nix), [`codex.nix`](../../modules/codex.nix), [`takt.nix`](../../modules/takt.nix), [`actrun.nix`](../../modules/actrun.nix))自体を import しません。プロファイルごとの差分は `if` 分岐ではなく `{ personal = ...; work = ...; }` という形のテーブルで列挙する方針です。

- **Karabiner-Elements の本体設定ファイルは管理しない**: `~/.config/karabiner/karabiner.json` はアプリ自身が接続デバイス情報や設定を頻繁に書き換える生きた状態ファイルのため、home-manager では symlink/上書き配布しません。代わりに [`config/karabiner/`](../../config/karabiner/) のルールを `~/.config/karabiner/assets/complex_modifications/` へ配置し、Karabiner-Elements の GUI から一度だけ有効化してもらう方式にしています。
- **macOS 対応は `isDarwin` special arg で分岐**: [`home.nix`](../../home.nix) は `pkgs.stdenv.isDarwin` ではなく、[`flake.nix`](../../flake.nix) が `system` 文字列から計算して渡す `isDarwin` special arg を使って macOS 専用モジュール([`modules/karabiner.nix`](../../modules/karabiner.nix) 等)の import を切り替えます。`imports` の評価中に `pkgs` を参照すると無限再帰になるため、この形にしています。

詳細な配置ルールは [`config/AGENTS.md`](../../config/AGENTS.md) と [`config/README.md`](../../config/README.md) を参照してください。
