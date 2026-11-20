# Codex のタスク確認フック

タスク確認フックはすべてのプロジェクトに適用されます。判定のために会話の一部やツールの呼び出し・結果を OpenAI に送り、追加のモデル利用が発生します。ユーザー入力と判定結果などは `${XDG_STATE_HOME:-~/.local/state}/codex-task-check` に保存します。

一時的に無効にするには Codex の `/hooks` を使います。設定を継続して変えるには [`modules/codex.nix`](../../modules/codex.nix) のフックに渡す `--mode` を変更し、Home Manager で反映します。

## 検証する

リポジトリのルートから次を実行します。

```sh
python3 -B -m unittest discover -s tests/codex-task-check -v
```

Codex の更新時は、実 CLI でフックの動作と信頼状態も確認します。ビルド手順と `CODEX_TASK_CHECK_CODEX`、`CODEX_TASK_CHECK_ACTIVATION` の指定は [CI の定義](../../.github/workflows/codex-task-check.yaml)を参照してください。

実モデルで合成ケースを評価する場合は `python3 tests/codex-task-check/evaluate.py --output /tmp/task-check-evaluation.json` を実行します。通常のテストとは異なり、追加のモデル利用が発生します。
