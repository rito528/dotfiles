---
name: issue-triage
description: open な issue 一覧を取得し、内容を分析して status ラベルを付与する
---

# issue-triage スキル

open な GitHub issue を取得し、内容を読んで `status: ready` または `status: needs-investigation` ラベルを付与する。

## 手順

### 1. open issue 一覧を取得

```bash
gh issue list --state open --json number,title,body,labels
```

### 2. 各 issue を分析してラベルを付与

各 issue について以下を判断する:

- `ai: ignore` ラベルがある場合は **スキップ**（AI 処理対象外）
- すでに `status:` で始まるラベルがある場合は **スキップ**
- issue の title + body を読んで以下のように分類:
  - 実装内容・手順が明確で、すぐに着手できる → **`status: ready`**
  - 仕様が不明確・調査が必要・影響範囲が不明 → **`status: needs-investigation`**

ラベル付与コマンド:

```bash
gh issue edit <number> --add-label "status: ready"
# または
gh issue edit <number> --add-label "status: needs-investigation"
```

### 3. 結果をユーザーに一覧表示

処理した issue の番号・タイトル・付与ラベルを表にして表示する。
スキップした issue も「スキップ済み」として表示する。

## 注意事項

- ラベルが存在しない場合は事前に作成が必要:
  ```bash
  gh label create "status: ready" --color "0E8A16" --description "実装可能な状態"
  gh label create "status: needs-investigation" --color "FFA500" --description "調査が必要"
  gh label create "status: investigated" --color "0075CA" --description "調査完了"
  gh label create "status: in-progress" --color "E4E669" --description "実装中"
  ```
- ラベルがすでに存在する場合、`gh label create` はエラーになるので `--force` または存在確認を行うこと
