---
name: promote-investigated
description: status:investigated な issue の調査結果コメントを読み、実装可能なら status:ready に昇格させる
---

# promote-investigated スキル

`status: investigated` ラベルが付いた issue を取得し、調査結果コメントを読んで実装可能かを判断し、`status: ready` へ昇格させる。

## 手順

### 1. 対象 issue を取得

```bash
gh issue list --label "status: investigated" --state open --json number,title,body,labels
```

取得後、`ai: ignore` ラベルが付いている issue は除外する。

対象 issue がなければ「昇格対象の issue がありません」と報告して終了。

### 2. 各 issue の調査結果コメントを確認

各 issue に対して最新のコメント一覧を取得し、調査結果を読む:

```bash
gh issue view <number> --comments --json comments
```

調査結果コメント（`## 調査結果` を含むもの）を探して内容を確認する。

### 3. 実装可否を判断してラベルを更新

調査結果をもとに以下のように判断する:

- **実装方針が明確で着手可能** → `status: ready` に昇格
  ```bash
  gh issue edit <number> --remove-label "status: investigated" --add-label "status: ready"
  ```

- **さらに調査が必要・仕様が不明確** → `status: needs-investigation` に戻し、理由をコメント
  ```bash
  gh issue edit <number> --remove-label "status: investigated" --add-label "status: needs-investigation"
  gh issue comment <number> --body "調査結果を確認しましたが、以下の点がまだ不明確なため再調査が必要です。\n\n<理由>"
  ```

- **対応不要・クローズすべき** → issue をクローズしてコメント
  ```bash
  gh issue close <number> --comment "<クローズ理由>"
  ```

### 4. 結果をユーザーに一覧表示

処理した issue の番号・タイトル・判断結果（昇格 / 再調査 / クローズ）を表にして表示する。

## 注意事項

- 調査結果コメントがない issue は `status: needs-investigation` に戻してスキップする
- ラベルが存在しない場合は事前に作成が必要:
  ```bash
  gh label create "status: ready" --color "0E8A16" --description "実装可能な状態"
  gh label create "status: needs-investigation" --color "FFA500" --description "調査が必要"
  ```
- ラベルがすでに存在する場合、`gh label create` はエラーになるので `--force` または存在確認を行うこと
