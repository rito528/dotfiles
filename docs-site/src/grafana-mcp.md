# Codex と Claude Code から Grafana MCP を使う

`mcp-grafana` は Nix パッケージとしてインストールされ、Codex と Claude Code が同じ
起動設定を使います。起動時に Doppler から必要な環境変数を受け取り、読み取り専用
モードで Grafana に接続します。あらかじめ Doppler CLI へログインしてください。

1. Grafana に最小限の RBAC 権限を持つ Service Account を作成し、トークンを発行します。
2. Doppler の project `mcp`、config `prd` に `GRAFANA_URL` と `GRAFANA_SERVICE_ACCOUNT_TOKEN` の 2 変数だけを登録します。
3. Home Manager の設定を反映して、各クライアントから MCP サーバーを確認します。

トークンの値を dotfiles に保存したり、Codex の親プロセスに設定したりしません。

```bash
home-manager switch --flake .
codex mcp list
claude mcp list
```

Codex と Claude Code を再起動した後、それぞれの `/mcp` でも接続状態を確認できます。

Grafana Cloud ではスタックの URL を `GRAFANA_URL` に設定します。ホスト上の Grafana
へ接続する場合は、`http://localhost:3000` のような URL を指定できます。

`--disable-write` は誤操作を防ぐための補助策であり、Grafana 側の RBAC に代わるものでは
ありません。MCP サーバーは必須扱いにしていないため、Doppler や Grafana への接続に
失敗しても Codex や Claude Code 全体の起動は止まりません。

`mcp-grafana` を更新するときは、[`modules/grafana-mcp.nix`](../../modules/grafana-mcp.nix) のバージョンと
hash を同時に更新してください。
