# Pi と共有スキル

個人プロファイルでは Home Manager が Pi を配備します。Pi は `~/.agents/skills/` とリポジトリ内の `.agents/skills/` を読み込むので、既存のスキルを共有できます。明示的に呼び出す場合は `/skill:<スキル名>` を使います。

認証情報は Pi 側で設定します。使うモデルの提供元は OpenAI を想定しています。`/login` で OpenAI の認証を設定し、`/model` でモデルを選択します。認証情報や普段の設定は手元の Pi が管理します。

## 完了条件を引き継ぐ

`agent-task goal <タスク名> --set '<完了条件>'` で登録すると、次に `agent-task run` で Pi を開いたときに完了条件が伝わります。途中で登録内容を変えた場合は、Pi を開き直してください。Pi は通常の対話で完了条件を参照します。

## 名前付きタスクを開く

```sh
agent-task start api-change --worktree
agent-task open api-change
agent-task run api-change -- pi --session-id api-change
```

同じタスクとセッション ID で起動すると、そのチェックアウトで会話を再開できます。Pi のステータス欄に現在のタスク名が表示され、プレビューや検証ログの保存先が Pi に伝わります。Git のブランチは Pi のステータス欄で確認できます。

調査やレビューのスキルに Codex 固有のツール名が出てくる場合は、その呼び出し先も Pi で使える必要があります。
