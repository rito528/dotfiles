# AGENTS.md for config/

このドキュメントは `config/` 配下の設定ファイルを編集するときの運用ルールを定義します。  
`config/` は home-manager によって実際のホームディレクトリへ配備されるため、ここでの変更はローカルサンプルではなく実運用設定の更新として扱ってください。

## 1. 基本方針

- `config/` 配下の変更は、配備先と影響範囲を意識して行う
- リポジトリ全体の原則はルート `AGENTS.md` に従う
- `config/` 配下の詳細な運用ルールや背景説明は各 README に分離する

## 2. ディレクトリごとの扱い

- `config/claude/`
  - Claude Code の hooks、permissions、status line などを管理する
  - 特に `settings.json` は実効権限を定義するため、単なる設定変更として扱わない
  - この配下の固有ルールは `config/claude/AGENTS.md` を参照する
  - 詳細は `config/claude/README.md` を参照する
- `config/agents/skills/`
  - home-manager 配備対象の Claude Code 向けスキル定義の正規配置
  - ここにあるスキルは `~/.claude/skills` と `~/.agents/skills` に反映される前提で扱う
  - 詳細は `config/agents/skills/README.md` を参照する
- `config/agents/`
  - AI Agent スキル定義配下の固有ルールは `config/agents/AGENTS.md` を参照する
- `config/git/hooks/`
  - Git hook として実際に配備されるファイル群
  - 開発補助ではなく、運用上の安全性に関わる設定として扱う

## 3. AI Agent 関連の注意点

- `config/agents/skills/` に追加するスキルは、グローバル配備して問題ないものに限定する
- 個人用の一時的な手順や、特定リポジトリ専用のスキルは原則として置かない
- 権限判断や危険操作に関わる説明を含む場合は、ルート `AGENTS.md` の原則と矛盾させない

## 4. permission 設定の扱い

- Claude のコマンド許可判断の原則はルート `AGENTS.md` に記述する
- Claude の実際の挙動は `config/claude/settings.json` を正とする
- 説明文と実設定がずれやすいため、permission を変更した場合は関連ドキュメントも同時に見直す

## 5. ドキュメント追加基準

`config/` 配下に新しい設定を追加するときは、次のいずれかに当てはまる場合に README か AGENTS.md を追加してください。

- 挙動や権限境界を変える
- グローバル反映されるため、ローカル設定だと誤解されやすい
- 配備先や役割が名前だけでは分かりにくい
- 変更時に特有のレビュー観点や禁止事項がある

単純な静的設定は、無理に個別ドキュメントを増やさず、Nix モジュールと簡潔な README 参照で十分です。
