---
name: investigate-issues
description: status:needs-investigation な issue を並列調査し、結果をコメントして status:investigated に更新する
---

# investigate-issues スキル

`status: needs-investigation` ラベルが付いた issue を取得し、各 issue に対して `issue-investigator` エージェントを並列で起動して調査・コメント投稿を行う。

## 手順

### 1. 対象 issue を取得

```bash
gh issue list --label "status: needs-investigation" --state open --json number,title,body,labels
```

取得後、`ai: ignore` ラベルが付いている issue は除外する。

対象 issue がなければ「調査が必要な issue がありません」と報告して終了。

### 2. 各 issue に対して issue-investigator agent を並列起動

取得した **すべての issue に対して同時に** Agent ツールで `issue-investigator` を呼び出す。

呼び出し時に以下の情報を context として渡す:
- issue 番号
- issue タイトル
- issue 本文

例 (複数 issue がある場合は並列で呼び出す):
> Agent tool: subagent_type=issue-investigator
> prompt: 以下の issue を調査してください。
> Issue #<number>: <title>
> <body>

### 3. 完了後に結果を報告

各エージェントの完了後、コメントが投稿された issue の URL を一覧でユーザーに報告する。

## 注意事項

- エージェントが失敗した issue は失敗理由とともに報告する
- 調査完了後は `status: investigated` ラベルが付与される。次のステップとして `/promote-investigated` スキルを実行すると、調査結果をもとに `status: ready` への昇格や再調査判断が行われる
