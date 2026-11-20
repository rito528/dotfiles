# Codex のタスク確認フック

タスク確認フックはすべてのプロジェクトに適用されます。判定のために会話の一部やツールの呼び出し・結果を OpenAI に送り、追加のモデル利用が発生します。ユーザー入力と判定結果などは `${XDG_STATE_HOME:-~/.local/state}/codex-task-check` に保存します。

一時的に無効にするには Codex の `/hooks` を使います。設定を継続して変えるには [`modules/codex.nix`](../../modules/codex.nix) のフックに渡す `--mode` を変更し、Home Manager で反映します。

## 判定基準

終了を判定するときは、依頼された成果と実際にできたことを比べます。相談調でも具体的な作成依頼なら、手順や構成案を示すだけでは完了とみなしません。既存の作業とのずれを指摘された場合も、理由を説明するだけでは修正を終えたことになりません。一方、説明・比較だけの依頼や将来の構想は、実装の許可とはみなしません。詳しい基準は [判定プロンプト](task-check/judge_prompt.txt) を参照してください。

## 検証する

リポジトリのルートから次を実行します。

```sh
python3 -B -m unittest discover -s tests/codex-task-check -v
```

判定モデルを替えるときは、[`task_check.py`](task-check/task_check.py) と [`judge_models.json`](task-check/judge_models.json) の指定を揃えます。Codex 自体の更新時は、実 CLI でフックの動作と信頼状態を確認します。ビルド手順と `CODEX_TASK_CHECK_CODEX`、`CODEX_TASK_CHECK_ACTIVATION` の指定は [CI の定義](../../.github/workflows/codex-task-check.yaml)を参照してください。

実モデルで合成ケースを評価する場合は `python3 tests/codex-task-check/evaluate.py --output /tmp/task-check-evaluation.json` を実行します。通常のテストとは異なり、追加のモデル利用が発生します。事前に決めた期待値と実行結果を比べ、失敗やタイムアウトも評価に含めます。合成ケースの結果だけで、実際の会話がどれだけ改善したかは判断しません。
