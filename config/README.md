# config/

`config/` は home-manager によって実際のホームディレクトリへ配備される生ファイルの置き場です。  
ここにあるファイルはサンプルやローカル専用設定ではなく、`home-manager switch` や `home-manager build` の対象になる実運用設定として扱います。

このディレクトリの編集ルールは `config/AGENTS.md` を参照してください。

## 基本方針

- `config/` 配下の変更は、反映先と影響範囲を意識して行う
- 挙動や権限境界を変える設定は、変更理由と運用上の注意点が読める状態にする
- リポジトリ全体の原則はルート `AGENTS.md` に記述し、`config/` 配下の運用ルールは `config/AGENTS.md` と各ディレクトリの README に分離する

## ディレクトリごとの扱い

- `config/agents/skills/`
  - home-manager 経由で `~/.claude/skills` と `~/.agents/skills` に反映される AI Agent 向けスキル定義の正規配置です
  - 詳細は `config/agents/skills/README.md` を参照してください
- `config/claude/`
  - Claude Code の設定、hooks、status line など、実際の挙動を決める設定です
  - 詳細は `config/claude/README.md` を参照してください
- `config/agents/AGENTS.md`, `config/claude/AGENTS.md`
  - AI Agent 関連サブディレクトリを編集するときの固有ルールです
  - 共通ルールに加えて、そのディレクトリで特に意識すべき観点を補います
- `config/AGENTS.md`
  - `config/` 配下を編集するときの運用ルールです
  - 権限境界やグローバル反映に関わる注意点をまとめています
## ドキュメントの追加基準

`config/` 配下に新しい設定を追加するときは、必ずしも毎回 README を作る必要はありません。次のいずれかに当てはまる場合に、そのディレクトリへ README を置く運用を推奨します。

- 外部ツールの挙動や権限境界を変える
- 利用者が「ローカル専用」だと誤解しやすいが、実際にはグローバルに反映される
- ファイルの役割や配置先が名前だけでは分かりにくい
- 変更時に守るべき運用ルールやレビュー観点がある

逆に、単純な静的設定で役割が明白なものは、README を増やさず `AGENTS.md` と Nix モジュール側の配備定義で十分です。
