# AGENTS.md for config/claude/

このドキュメントは `config/claude/` 配下を編集するときの運用ルールを定義します。  
共通ルールは `config/AGENTS.md` を前提とし、このファイルでは Claude Code の実効設定に固有の注意点だけを扱います。

## 1. このディレクトリの責務

- `config/claude/settings.json` は Claude Code の hooks、permissions、plugin 有効化、status line を定義する実効設定
- `hooks/` と `statusline.py` は Claude の実行時挙動に直接影響する配備物

## 2. 編集方針

- `settings.json` の変更は、UI 調整ではなく実運用ポリシーの更新として扱う
- `permissions` を変える場合は、`config/AGENTS.md` の抽象原則と `config/claude/README.md` の説明も同時に見直す
- hooks や補助スクリプトは、非対話環境や CI 環境でも破綻しにくい形を優先する

## 3. permission の観点

- `allow` は無確認実行でも安全なものに限定する
- `ask` は外部書き込み、破壊的操作、取得系でもリスクの高いものを中心に置く
- `deny` は秘密情報、権限昇格、履歴破壊、任意コード実行に対して保守的に維持する
- 説明文よりも `settings.json` の内容が実際の挙動を決めるため、ドキュメントだけ更新して終わらせない

## 4. レビュー観点

- permission の変更が既存の安全境界を広げすぎていないか
- hooks がユーザー体験や CI 実行を不必要に阻害しないか
- ローカル専用の事情をグローバル設定へ持ち込んでいないか
- `config/claude/README.md` の説明と矛盾していないか
