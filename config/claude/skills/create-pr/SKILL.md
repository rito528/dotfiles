---
name: create-pr
description: GitHub に Pull Request を作成するスキル。ユーザーが「PRを作って」「プルリクエストを出して」「PR作成して」と言ったとき、またはコミット済みの変更をレビューに出したいときに使用する。
---

# PR 作成スキル

現在の変更から GitHub Pull Request を作成する。未コミットの変更がある場合は git-commit スキルを使ってコミットしてから PR を作成する。

## 前提条件

- `gh` CLI が認証済みであること

## 手順

### 1. 現状の確認

以下を並列で実行して状況を把握する:

```bash
git status
git log --oneline -10
git branch -vv
```

### 2. コミットされていない変更の処理

未コミットの変更や未追跡のファイルがある場合は、git-commit スキル (`/git-commit`) を使ってコミットする。git-commit スキルがブランチの作成やコミットメッセージの作成を担当する。

**注意**: `/git-commit` は内部で `/ensure-branch` を呼ぶため、Step 2 を実行した場合は Step 3 をスキップしてよい。

### 3. ブランチの確認（Step 2 を実行しなかった場合のみ）

未コミットの変更がなく Step 2 をスキップした場合のみ、`/ensure-branch` スキルを使って作業ブランチが適切かどうかを確認・切り替える。

**重要**: ブランチの確認・切り替えが完了したら、必ず Step 4 に進むこと。ここで処理を止めないこと。

### 4. 差分の分析

メインブランチからの全変更を確認する:

```bash
git log main..HEAD --oneline
git diff main...HEAD --stat
```

**すべてのコミット** を確認すること。最新コミットだけでなく、PR に含まれる全コミットの内容を把握してからタイトルと本文を作成する。

### 5. PR タイトルと本文の作成

#### タイトル
- 70文字以内で簡潔に
- 変更の目的がわかるように書く
- 詳細はタイトルではなく本文に書く

#### 本文のテンプレート

```markdown
## 概要
<!-- 変更の目的と内容を箇条書き 1〜3 点 -->

## テスト計画
<!-- テストや検証の方法をチェックリストで記述 -->

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

### 6. push と PR 作成

```bash
# リモートに push（未 push の場合）
git push -u origin HEAD

# PR 作成（本文は HEREDOC で渡す）
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## 概要
- ...

## テスト計画
- [ ] ...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### 7. 完了報告

作成した PR の URL をユーザーに伝える。
