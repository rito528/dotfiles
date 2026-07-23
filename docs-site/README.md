# docs-site

このディレクトリは [mdBook](https://rust-lang.github.io/mdBook/) によるドキュメントサイトのソースです。`main` への push で GitHub Pages に自動デプロイされます。

## ローカルでプレビューする

```bash
mdbook serve docs-site --open
```

`mdbook` は [`modules/packages.nix`](../modules/packages.nix) の `home.packages` で管理しています。

## 章を追加・変更する場合

- [`src/`](src/) 配下に Markdown ファイルを追加し、[`src/SUMMARY.md`](src/SUMMARY.md) にエントリを追加してください。
- ビルド確認は `mdbook build docs-site` で行います。
