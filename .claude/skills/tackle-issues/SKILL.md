---
name: tackle-issues
description: status:ready な issue に対して issue-implementer agent を並列起動し、実装→PR作成を行う
---

# tackle-issues スキル

`status: ready` ラベルが付いた issue を取得し、各 issue に対して `issue-implementer` エージェントを並列で起動して実装・PR 作成を行う。

## 重要な制約

**このスキルを実行するメインエージェントは issue の実装を一切行わないこと。**
コードの読み取り・編集・コミット・PR 作成はすべて `issue-implementer` サブエージェントに委譲する。
メインエージェントの役割は「issue 一覧の取得」と「サブエージェントの起動・結果報告」のみ。

## 手順

### 1. 対象 issue を取得

```bash
gh issue list --label "status: ready" --state open --json number,title,body,labels
```

取得後、`ai: ignore` ラベルが付いている issue は除外する。

対象 issue がなければ「実装可能な issue がありません」と報告して終了。

### 2. 各 issue に対して issue-implementer agent を並列起動

取得した **すべての issue に対して同時に** Agent ツールで `issue-implementer` を呼び出す。

呼び出し時に以下の情報を context として渡す:
- issue 番号
- issue タイトル
- issue 本文

`isolation: worktree` を指定して隔離環境で実行する。

例 (複数 issue がある場合は並列で呼び出す):
> Agent tool: subagent_type=issue-implementer, isolation=worktree
> prompt: 以下の issue を実装してください。
> Issue #<number>: <title>
> <body>

### 3. 完了後に結果を報告

各エージェントの完了後、作成された PR の URL を一覧でユーザーに報告する。

## 注意事項

- issue が多い場合でも並列実行（並列数の上限は 5 程度）
- エージェントが失敗した issue は失敗理由とともに報告する
