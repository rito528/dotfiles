---
name: add-script
description: install/ 配下に新しいセットアップ用シェルスクリプトを追加するスキル
---

# add-script スキル

`install/` 配下に冪等なセットアップ用シェルスクリプトを追加し、必要に応じて `setup.sh` に組み込む。

## 手順

### 1. 配置先を決める

- `install/common/`: OS に依存しない処理
- `install/ubuntu/`: Ubuntu / Debian 固有の処理

### 2. スクリプトを作成する

以下のテンプレートをベースに対象ファイルを作成する。

```bash
#!/usr/bin/env bash
# <スクリプトの説明>
# Usage: ./install/<type>/<name>.sh

set -euo pipefail

# 冪等性チェック: 処理済みなら早期終了
if <already_done_condition>; then
  echo "<name>: already done. Skipping."
  exit 0
fi

# 本処理
```

必須ルール:

- `#!/usr/bin/env bash` を使う
- `set -euo pipefail` を入れる
- 処理の先頭で「すでに適用済みか」を確認し、済みなら `exit 0` する
- CI で分岐が必要なら `[ "${CI:-}" = "true" ]` を使う

### 3. 実行権限を付与する

```bash
chmod +x install/<type>/<name>.sh
```

git は実行ビットを追跡するため、実行権限を付与した状態でコミットする。

### 4. shellcheck を実行する

```bash
shellcheck install/<type>/<name>.sh
```

警告とエラーを解消する。

### 5. 必要なら `setup.sh` に組み込む

セットアップフローに含める場合は該当する `setup.sh` に追記する。

```bash
echo "==> <説明>..."
"$REPO_DIR/install/<type>/<name>.sh"
```

### 6. 変更を検証してコミットする

必要に応じて関連するセットアップフローを確認し、コミットが必要なら `git-commit` 系のスキルや通常の git 手順を使う。

## 注意事項

- `sudo` が必要な処理は CI でスキップする: `[ "${CI:-}" = "true" ] && { echo "skip in CI"; exit 0; }`
- 外部コマンドに依存する場合は `command -v <cmd>` で存在確認する
- `REPO_DIR` が必要なら `REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"` のように階層に応じて組み立てる
- `echo` より `printf` の方が shellcheck 的に安全な場面がある
