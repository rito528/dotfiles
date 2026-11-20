# Pi の使い方

Pi は Home Manager の個人プロファイルで使えます。`/login openai` で ChatGPT アカウントにサインインし、`/model` でモデルを選びます。共有スキルは `/skill:<スキル名>` で呼び出せます。

## タスクの作業先と会話を再開する

```sh
agent-task start api-change --worktree
agent-task open api-change
agent-task run api-change -- pi --session-id api-change
```

再開するときは、同じタスク名とセッション ID で `agent-task run` を実行します。完了条件の登録などは [agent-task の使い方](../../modules/scripts/agent-task/README.md#完了条件を残す)を参照してください。

## タスク確認を止める

タスク確認は会話の一部を OpenAI に送って判定します。判定結果などはローカルに記録しますが、送った会話の原文はそこに保存しません。追加のモデル利用が発生します。そのセッションだけ無効にするには `PI_TASK_CHECK=off pi` で起動してください。
