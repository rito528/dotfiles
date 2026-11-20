# AI エージェントの作業先をタスク名で管理する

個人プロファイルで使える `agent-task` は、Git リポジトリごとにタスク名と作業先を記録します。同じタスク名で始め直すと、登録したパスとブランチを確認してから再利用します。

```sh
agent-task start docs-review
agent-task start api-change --worktree
agent-task list
agent-task open api-change
agent-task run api-change -- codex --add-dir "$(agent-task artifacts api-change)"
```

- `start` は現在のチェックアウトを登録します。並行して編集するときだけ `--worktree` を付けます。専用のブランチ `agent-task/<名前>` を現在のコミットから作り、メインのチェックアウトの隣にある `<リポジトリ名>.worktrees/<名前>` に配置します。
- `list` は登録済みのタスクについて、状態、ブランチ、チェックアウト、成果物のパスを表示します。`run` で起動中のタスクには `running` が付きます。自動化にはパスだけを返す `path` と `artifacts` を使えます。
- `open` は登録したチェックアウトを VS Code の新しいウィンドウで開きます。
- `run` は登録したチェックアウトを作業ディレクトリにしてコマンドを起動し、`AGENT_TASK_NAME`、`AGENT_TASK_ROOT`、`AGENT_TASK_ARTIFACTS` を渡します。Codex の書き込み範囲に成果物ディレクトリを含めるには、上の例のように `--add-dir` を指定します。
- プレビュー、比較結果、検証ログなど、あとから参照するファイルは、メインのチェックアウトの `.work/agent-tasks/<名前>/` に意味のある名前で置きます。このディレクトリは Git のローカルの除外設定に追加されます。
- エージェントとエディターを閉じたら、別のチェックアウトから `agent-task close <名前>` を実行します。専用worktreeは、実行中のコマンド、途中の Git 操作、未コミット・未追跡・無視対象のファイルがある間は残します。ブランチと成果物は終了後も残るので、同じタスク名で再開できます。

登録はそのリポジトリの共通 Git ディレクトリに保存します。既存のworktreeを使う場合は、そこで `start` を実行して登録できます。手動で場所やブランチを変えた場合は、登録したチェックアウトを復元してから再開してください。タスクに登録されていないworktreeは Git や `git-wt` で管理できます。

VS Code に正しいチェックアウトを開いたあと、定義ジャンプが効かない場合は、言語サーバーのプロジェクト設定を確認してください。たとえば複数の Cargo プロジェクトがある場合、使う `Cargo.toml` を `.code-workspace` の `rust-analyzer.linkedProjects` に指定できます。

新規作成時に Git の `post-checkout` フックが失敗した場合、チェックアウトが作られていればタスクを登録し、フックのエラーを表示します。フックの失敗原因を直してから、同じタスク名で作業先を開き直せます。

Pi で同じ作業先と会話を開き直す手順は、[Pi と共有スキル](../../../config/pi/README.md)を参照してください。
