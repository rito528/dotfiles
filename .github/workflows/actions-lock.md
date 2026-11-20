# GitHub Actions の lockfile 更新手順

ワークフローを追加したり、`uses:` を変更したりしたら、認証済みの GitHub CLI でリポジトリのルートから次を実行します。拡張機能のバージョンは [CI](actions-lock.yaml) に合わせてください。

```sh
gh extension install github/gh-actions-lock --pin v0.4.0
gh actions-lock --no-interactive
gh actions-lock --verify
```

[actions.lock](actions.lock) は手で編集せず、ワークフローと一緒にコミットします。既存のブランチ参照の固定先を更新するときは `gh actions-lock --relock --no-interactive` を使い、ほかの可変参照も更新されるため差分全体を確認してから `--verify` を実行します。
