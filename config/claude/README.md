# config/claude/

`config/claude/` は Claude Code の実運用設定を管理するディレクトリです。  
この配下のファイルは [modules/claude.nix](/home/rito528/dotfiles/modules/claude.nix:1) によって `~/.claude/` へ配置されます。

このディレクトリを編集する前に、`config/AGENTS.md` と `config/claude/AGENTS.md` も参照してください。

## 含まれるもの

- `settings.json`
  - Claude Code の hooks、permission、plugin 有効化、status line などを定義します
- `hooks/`
  - Claude が特定イベント時に実行する補助スクリプトです
- `statusline.py`
  - Claude の status line 表示用スクリプトです

## `settings.json` の位置づけ

`settings.json` は単なる UI 設定ではなく、Claude Code がこのリポジトリでどこまで実行してよいかを定める実効仕様です。  
特に `permissions` は、コマンド実行の安全境界をコードとして表現しているため、変更時は通常の設定変更より慎重に扱います。

## permission 方針

- 抽象的な判断基準は `config/AGENTS.md` に記述する
- 実際に有効なルールは `settings.json` を正とする
- `config/AGENTS.md`、`config/claude/AGENTS.md`、`settings.json` に関わる変更では、説明と実装の不整合を残さない

## 変更時の観点

- `allow` に追加するコマンドは、本当に無確認実行で安全か
- `ask` に置くべき操作を `allow` に入れていないか
- `deny` が秘密情報・破壊的操作・権限昇格を十分に防げているか
- hooks や status line が CI や非対話環境で破綻しないか

## 補足

Claude の権限ルールは、リポジトリ内の説明文より `settings.json` の内容が最終的な挙動を決めます。  
そのため、判断基準を文書化する場合でも、ルール一覧を別文書へ重複転記しすぎず、役割と意図の説明を優先します。
