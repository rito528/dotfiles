# add-script スキル

`install/` 配下にシェルスクリプトを追加するワークフロー。

## 手順

### 1. 配置先の決定

- `install/common/` … OS に依存しない処理
- `install/ubuntu/` … Ubuntu / Debian 固有の処理

### 2. スクリプトの雛形作成

Write ツールで以下のテンプレートをベースに作成する。

```bash
#!/usr/bin/env bash
# <スクリプトの説明>
# Usage: ./install/<type>/<name>.sh

set -euo pipefail

# 冪等性チェック: 処理済みなら早期 exit
if <already_done_condition>; then
  echo "<name>: already done. Skipping."
  exit 0
fi

# 本処理
```

**必須ルール:**
- `#!/usr/bin/env bash` を使う（PATH から bash を探す）
- `set -euo pipefail` 必須
- 処理の先頭で「すでに適用済みか」チェックし、済みなら `exit 0`（冪等性）
- CI 対応が必要な場合は `[ "${CI:-}" = "true" ]` で分岐（`sudo` を使う箇所など）

### 3. 実行権限の付与

```bash
chmod +x install/<type>/<name>.sh
```

git は実行ビットを追跡するため、`chmod +x` 後にコミットすれば `git clone` 後も実行可能。

### 4. shellcheck の実行

```bash
shellcheck install/<type>/<name>.sh
```

すべての警告・エラーを解消する。

### 5. setup.sh への追記（任意）

スクリプトをセットアップフローに組み込む場合は該当の `setup.sh` に追記する。

```bash
echo "==> <説明>..."
"$REPO_DIR/install/<type>/<name>.sh"
```

### 6. コミット

`/git-commit` スキルを呼び出してコミットする。

## 注意事項

- `sudo` を使う場合は CI でスキップ: `[ "${CI:-}" = "true" ] && { echo "skip in CI"; exit 0; }`
- 外部コマンドへの依存は `command -v <cmd>` で存在確認する
- `REPO_DIR` が必要な場合: `REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"` （階層に応じて `..` の数を調整）
- `echo` より `printf` を使うと shellcheck の警告を避けられる場合がある
