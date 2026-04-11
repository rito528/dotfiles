# AGENTS.md for config/

このドキュメントは `config/` 配下の設定ファイルを編集するときの運用ルールを定義します。  
`config/` は home-manager によって実際のホームディレクトリへ配備されるため、ここでの変更はローカルサンプルではなく実運用設定の更新として扱ってください。

## 1. 基本方針

- `config/` 配下の変更は、配備先と影響範囲を意識して行う
- リポジトリ全体の原則はルート `AGENTS.md` に従う
- `config/` 配下の詳細な運用ルールや背景説明は各 README に分離する

## 2. ディレクトリごとの扱い

- `config/claude/`
  - Claude Code の hooks、permissions、status line などを管理する
  - 特に `settings.json` は実効権限を定義するため、単なる設定変更として扱わない
  - この配下の固有ルールは `config/claude/AGENTS.md` を参照する
  - 詳細は `config/claude/README.md` を参照する
- `config/agents/skills/`
  - home-manager 配備対象の Claude Code 向けスキル定義の正規配置
  - ここにあるスキルは `~/.claude/skills` と `~/.agents/skills` に反映される前提で扱う
  - 詳細は `config/agents/skills/README.md` を参照する
- `config/agents/`
  - AI Agent スキル定義配下の固有ルールは `config/agents/AGENTS.md` を参照する
- `config/git/hooks/`
  - Git hook として実際に配備されるファイル群
  - 開発補助ではなく、運用上の安全性に関わる設定として扱う

## 3. AI Agent 関連の注意点

- `config/agents/skills/` に追加するスキルは、グローバル配備して問題ないものに限定する
- 個人用の一時的な手順や、特定リポジトリ専用のスキルは原則として置かない
- 権限判断や危険操作に関わる説明を含む場合は、ルート `AGENTS.md` の原則と矛盾させない

## 4. AI Agent に対する許可 / 拒否コマンドの原則

`config/claude/settings.json` の `permissions` セクションで、Claude Code を含む AI Agent のコマンド実行境界を制御します。  
以下の原則に従って `allow` / `ask` / `deny` を分類し、実際に有効なルール一覧は `config/claude/settings.json` を正とします。

### 4.1. 許可 (allow) の基準

ユーザーへの確認なしに実行してよいコマンドの条件：

- **読み取り専用の操作**: ファイルシステムやリポジトリの状態を読むだけで、変更を加えない。
  - 例: `git status`, `git diff`, `git log`, `git branch`, `ls`, `grep`, `shellcheck`, `nixfmt`
- **ローカルへの影響のみ**: リモートリポジトリや外部サービスに変更を及ぼさない。
  - 例: `git fetch`, `git switch`, `git pull` (取り込みのみ)
- **ローカルな Git 操作**: ワークツリーやローカル履歴に対する変更で完結し、リモートへの反映を伴わない。
  - 例: `git add`, `git commit`
- **ビルド・検証**: ローカル環境のビルドや検証を行う。
  - 例: `home-manager build`, `nix`, `cargo`
- **GitHub の Read 操作**: リモートへの書き込みを行わない参照操作。
  - 例: `gh issue view`, `gh issue list`, `gh pr view`, `gh run view`

### 4.2. 要確認 (ask) の基準

ユーザーへの確認を必要とするコマンドの条件：

- **ファイルシステムへの破壊的操作**: ファイルの削除など、元に戻せない可能性がある操作。
  - 例: `rm`
- **外部からのデータ取得**: ネットワーク経由でデータをダウンロードする。
  - 例: `wget`, `curl`
- **Git の状態変更のうち破壊性や退避操作を伴うもの**: 履歴やワークツリーの意図を誤りやすい操作。
  - 例: `git stash`, `git rm`
- **リモートへの書き込み**: リモートリポジトリに変更を反映する。
  - 例: `git push`
- **GitHub の Write 操作**: issue / PR など外部サービスへの書き込み。
  - 例: `gh pr create`, `gh issue comment`

### 4.3. 拒否 (deny) の基準

いかなる場合も実行してはならないコマンドの条件：

- **破壊的な Git 操作**: 履歴の書き換えや強制的なリセット。
  - 例: `git reset --hard`
- **特権昇格**: `sudo` による管理者権限の取得。
- **機密情報へのアクセス**: 秘密鍵・APIトークン・環境変数ファイルの読み書き。
  - 例: `.env.*` ファイルの Read/Edit, `~/.ssh/**` の Read/Edit
- **シークレット管理ツール**: Doppler など機密情報を扱うツールの実行。
  - 例: `doppler`
- **ネットワーク接続ツール**: 任意のホストへの接続が可能なコマンド。
  - 例: `nc` (netcat)
- **汎用スクリプト実行**: 任意コードの実行につながる恐れがあるインタープリタ。
  - 例: `python`, `python3`

## 5. permission 設定の扱い

- AI Agent のコマンド許可判断の原則はこの `config/AGENTS.md` に記述する
- Claude の実際の挙動は `config/claude/settings.json` を正とする
- 説明文と実設定がずれやすいため、permission を変更した場合は関連ドキュメントも同時に見直す

## 6. ドキュメント追加基準

`config/` 配下に新しい設定を追加するときは、次のいずれかに当てはまる場合に README か AGENTS.md を追加してください。

- 挙動や権限境界を変える
- グローバル反映されるため、ローカル設定だと誤解されやすい
- 配備先や役割が名前だけでは分かりにくい
- 変更時に特有のレビュー観点や禁止事項がある

単純な静的設定は、無理に個別ドキュメントを増やさず、Nix モジュールと簡潔な README 参照で十分です。
