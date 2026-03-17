# AI 自律 issue 実装ワークフロー

このドキュメントでは、Claude Code を使って GitHub issue をトリアージ・調査・実装する一連のワークフローについて説明します。

## 概要

`.claude/skills/` 以下に定義された 3 つのスキルを順に実行することで、open な issue の分類から実装・PR 作成までを自動化できます。

```
open issues
    │
    ▼
/issue-triage          ── status ラベルを付与
    │
    ├─ status: needs-investigation
    │       ▼
    │  /investigate-issues  ── 調査してコメント → status: investigated
    │       ▼
    │  (内容を確認し status: ready に手動昇格)
    │
    └─ status: ready
            ▼
       /tackle-issues   ── 実装 → PR 作成
```

---

## スキル一覧

### `/issue-triage`

open な issue を読んで `status: ready` または `status: needs-investigation` ラベルを付与します。

**使い方**

Claude Code のチャットで次のように入力します。

```
/issue-triage
```

**動作**

1. `gh issue list --state open` で issue 一覧を取得する。
2. `ai: ignore` ラベルがある issue はスキップする。
3. すでに `status:` ラベルがある issue もスキップする。
4. 残りの issue を内容で分類してラベルを付与する。
   - 実装内容が明確で即着手できる → `status: ready`
   - 仕様が不明瞭・調査が必要 → `status: needs-investigation`
5. 処理結果を一覧で表示する。

---

### `/investigate-issues`

`status: needs-investigation` の issue をコードベースや外部情報を使って調査し、結果を issue にコメントします。

**使い方**

```
/investigate-issues
```

**動作**

1. `status: needs-investigation` の issue を取得する。
2. 各 issue に対して `issue-investigator` エージェントを並列起動する。
3. 各エージェントはコードベース調査・外部調査を行い、以下の形式で issue にコメントする。
   - 現状 / 影響範囲 / 実装方針案 / 懸念点
4. 調査完了後、ラベルを `status: needs-investigation` から `status: investigated` に変更する。
5. 完了した issue の URL を一覧で報告する。

> 調査が完了した issue を実装フェーズに進めるには、人間が内容を確認してラベルを `status: ready` に変更してください。

---

### `/tackle-issues`

`status: ready` の issue を並列実装して PR を作成します。

**使い方**

```
/tackle-issues
```

**動作**

1. `status: ready` の issue を取得する。
2. 各 issue に対して `issue-implementer` エージェントを worktree 隔離環境で並列起動する（上限 5 並列）。
3. 各エージェントは以下を行う。
   - コードベースを調査して実装する。
   - `git-commit` スキルでコミットする。
   - `create-pr` スキルで PR を作成する。
   - issue に PR URL をコメントする。
   - issue に `status: in-progress` ラベルを付与する。
4. 完了した PR の URL を一覧で報告する。

---

## ラベル体系

| ラベル | 意味 |
|---|---|
| `status: ready` | 実装可能な状態。`/tackle-issues` の対象。 |
| `status: needs-investigation` | 仕様不明瞭・調査が必要。`/investigate-issues` の対象。 |
| `status: investigated` | 調査完了。人間が確認して `status: ready` に昇格させる。 |
| `status: in-progress` | 実装エージェントが着手中または PR 作成済み。 |
| `ai: ignore` | AI 処理の対象外。すべてのスキルでスキップされる。 |

ラベルが存在しない場合は事前に作成してください。

```bash
gh label create "status: ready" --color "0E8A16" --description "実装可能な状態"
gh label create "status: needs-investigation" --color "FFA500" --description "調査が必要"
gh label create "status: investigated" --color "0075CA" --description "調査完了"
gh label create "status: in-progress" --color "E4E669" --description "実装中"
gh label create "ai: ignore" --color "CCCCCC" --description "AI 処理対象外"
```

---

## 構成ファイル

```
.claude/
├── skills/
│   ├── issue-triage/SKILL.md        # issue-triage スキル定義
│   ├── investigate-issues/SKILL.md  # investigate-issues スキル定義
│   └── tackle-issues/SKILL.md       # tackle-issues スキル定義
└── agents/
    ├── issue-investigator.md        # 調査エージェント定義
    └── issue-implementer.md         # 実装エージェント定義
```

- **スキル** (`skills/`): `/スキル名` で呼び出せるトップレベルの手順書。
- **エージェント** (`agents/`): スキルから内部的に呼び出されるサブエージェント。直接呼び出すことは想定していません。

---

## 典型的な使い方

issue が溜まったときに以下の順で実行します。

```
1. /issue-triage              ← 全 open issue にステータスラベルを付与
2. /investigate-issues        ← 調査が必要な issue を自動調査
3. (調査結果を確認して ready に昇格)
4. /tackle-issues             ← ready な issue を一括実装・PR 作成
```

特定の issue を AI 処理の対象外にしたい場合は `ai: ignore` ラベルを付与してください。
