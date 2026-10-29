# GitHub Actions の依存関係

ワークフローの `uses:` にはバージョンタグを記述し、実行するコミットと推移的な依存関係は
[actions.lock](workflows/actions.lock) に固定する。既存の `main` 参照も、lockfile に記録されたコミットで実行される。
同じリポジトリ内の再利用可能ワークフローは、呼び出し元と同じコミットを使う相対参照のままにする。

## ワークフローを変更するとき

認証済みの GitHub CLI に、生成・検証用の拡張をインストールする。

```sh
gh extension install github/gh-actions-lock --pin v0.4.0
```

ワークフローの追加や `uses:` の変更後は、リポジトリのルートで次を実行し、ワークフローと lockfile を一緒にコミットする。

```sh
gh actions-lock --no-interactive
gh actions-lock --verify
```

lockfile は手で編集しない。CI でも `--verify` により、依存関係の記録漏れや固定先の正当性を確認し、結果を CI Gate に含める。
通信なしで記録漏れだけを確認したい場合は `gh actions-lock --verify-local` を使う。
生成ファイルのインデントは CLI の出力に従う。

## Renovate による更新

Renovate の `github-actions` manager は `actions.lock` を検出し、Action のバージョン更新時に lockfile も同じ PR で再生成する。
追加の更新用ワークフローや `postUpgradeTasks` は不要。`renovate.json` では `pinDigests: false` とし、コミットの固定を lockfile に任せる。
既存の「公開から 7 日待つ」「日曜に自動マージする」という設定は継続する。

`main` などのブランチ参照にはバージョン順序がなく、通常のタグ更新と同じ方法では追従できない。
既存の EditorConfig Action の `main` を進める場合は、上流の差分を確認したうえで、次のコマンドで固定先を更新する。
`--relock` は他の可変タグ・ブランチも更新対象にするため、lockfile の差分全体を確認する。

```sh
gh actions-lock --relock --no-interactive
gh actions-lock --verify
```

2026-10-29 時点では、GitHub 側は GA だが Renovate の公式ドキュメントでは lockfile 対応が experimental とされている。
Renovate は生成 CLI のバージョンを固定して導入する。セルフホストで `binarySource=global` を使う場合は、運用側で `gh` と拡張を用意する必要がある。
このリポジトリの Renovate Config Check は設定と依存関係の抽出を調べるもので、GitHub App が更新 PR に lockfile を含めることまで再現するものではない。
導入後の最初の更新 PR では、ワークフローと lockfile が一緒に更新されることを確認する。

公式資料:

- [GitHub Actions lockfile の GA 公開](https://github.blog/changelog/2026-10-28-github-actions-workflow-lockfiles-are-generally-available/)
- [生成 CLI の使い方と制約](https://github.com/github/gh-actions-lock)
- [Renovate の lockfile 対応](https://docs.renovatebot.com/modules/manager/github-actions/#github-actions-lockfile-actionslock)
