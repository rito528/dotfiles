# Pi と共有スキル

個人プロファイルでは Home Manager が Pi を配備します。Pi は `~/.agents/skills/` とリポジトリ内の `.agents/skills/` を読み込むので、既存のスキルを共有できます。明示的に呼び出す場合は `/skill:<スキル名>` を使います。

Pi で `/login openai` を実行し、ChatGPT アカウントでサインインしてから、`/model` で OpenAI のモデルを選びます。認証情報や普段の設定は手元の Pi が管理します。

## 名前付きタスクを開く

```sh
agent-task start api-change --worktree
agent-task open api-change
agent-task run api-change -- pi --session-id api-change
```

同じタスクとセッション ID で起動すると、そのチェックアウトで会話を再開できます。Pi のステータス欄に現在のタスク名が表示され、プレビューや検証ログの保存先が Pi に伝わります。Git のブランチは Pi のステータス欄で確認できます。

## Grafana MCP

Pi の `/mcp` で Grafana の接続状態を確認できます。接続には Codex と共通の Doppler 設定を使います。配備する Grafana サーバーの書き込み機能は無効です。`mcp.json` に同名の設定があれば、その設定を Pi が優先します。

## 独立した調査やレビューを任せる

Pi に「subagentにこの変更をレビューさせて」のように頼むと、選択中の OpenAI モデルで別のプロセスを起動します。子には依頼文だけを渡し、親の会話は引き継ぎません。子のツールはファイルの読み取り、検索、一覧に限ります。MCP は親セッションから使えます。シェルでは `rg` を優先し、Pi の `grep` ツールも ripgrep を使います。
