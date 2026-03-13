# npm パッケージ管理

## 要件

- npm パッケージの管理方法を確立させる
  - pnpm を使用しているパッケージには [nixpkgs の `pnpm.buildNodePackage`](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/javascript.section.md) を使用すること
- npm パッケージとして、グローバルスコープに [difit](https://github.com/yoshiko-pg/difit) をインストールするようにする
  - npm パッケージは `/nix/modules/npm` に配置する
- パッケージのバージョン更新は Renovate が自動で PR を出す運用とする

## ディレクトリ構成
```
nix/
└── modules/
    └── npm/
        ├── default.nix        # モジュールのエントリポイント。パッケージ一覧を home.packages に追加する
        └── packages/
            └── difit.nix      # difit パッケージ定義
```

## 各ファイルの仕様

### `default.nix`

- `packages/` 以下のパッケージ定義を収集し、`home.packages` に追加する
- 新しいパッケージを追加する際は `packages/` にファイルを追加するだけでよい構造にする

### `packages/difit.nix`

- `pnpm.buildNodePackage` を使って difit をビルドする
- ソースは `fetchFromGitHub` で取得する
- 依存関係は `pnpm.fetchDeps` で取得し、`pnpm-lock.yaml` のハッシュを `pnpmDepsHash` に指定する
- difit のビルドには Node.js 21 以上が必要なため、`nodejs_22` を指定する
- ビルド成果物から `difit` コマンドが `$out/bin/difit` として利用できるようにする

## Renovate の設定

- `version`・`src` の `hash`・`pnpmDepsHash` の3つを更新する PR を自動で出すよう設定する
- `pnpmDepsHash` の自動更新には `nix-update` を Renovate の postUpgradeTasks で実行することで対応する
  - 具体的な Renovate 設定は別 spec で定義する

## 将来のパッケージ追加手順

新しいパッケージを追加する場合：

1. `nix/modules/npm/packages/<package-name>.nix` を作成する
2. パッケージが `package-lock.json` を持つ場合は `buildNpmPackage` を、`pnpm-lock.yaml` を持つ場合は `pnpm.buildNodePackage` を使用する
3. `pnpmDepsHash` は `nix run nixpkgs#prefetch-npm-deps -- pnpm-lock.yaml` で計算する
4. Renovate が自動更新できるよう `version` を変数として明示的に定義する
