---
name: add-npm-package
description: nix/modules/npm/packages/ に新しい npm/pnpm パッケージを追加するスキル
---

# npm パッケージ追加スキル

`nix/modules/npm/packages/` に新しいパッケージの `.nix` ファイルを作成し、`home-manager switch` で反映する。

## 手順

### 1. 最新バージョンの確認

```bash
curl -s https://api.github.com/repos/<owner>/<repo>/releases/latest | grep '"tag_name"'
```

### 2. `src.hash` の取得

ダミーハッシュを入れてビルドし、エラーから正しい値を読み取る。

```nix
src = pkgs.fetchFromGitHub {
  owner = "<owner>";
  repo = "<repo>";
  rev = "v${version}";
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # ダミー
};
```

```bash
nix-build /tmp/test.nix 2>&1 | grep "got:"
# → got: sha256-xxxxx  ← この値を使う
```

### 3. `pnpmDeps.hash` の取得 (pnpm プロジェクトの場合)

まず lockfile のバージョンを確認する:

```bash
curl -s https://raw.githubusercontent.com/<owner>/<repo>/v<version>/pnpm-lock.yaml | head -1
# lockfileVersion: '9.0' → fetcherVersion = 1
```

| lockfileVersion | fetcherVersion |
|---|---|
| `'9.0'` (pnpm v9以降) | `1` |
| `'6.0'` 以前 | 不要 (省略) |

同様にダミーハッシュで失敗させて取得:

```nix
pnpmDeps = pkgs.pnpm.fetchDeps {
  pname = "<pname>";
  inherit version src;
  fetcherVersion = 1;
  hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # ダミー
};
```

### 4. `buildPhase` の確認

`package.json` の `scripts` を確認し、CLI と Web UI の両方をビルドするスクリプトを選ぶ:

```bash
curl -s https://raw.githubusercontent.com/<owner>/<repo>/v<version>/package.json \
  | python3 -c "import json,sys; d=json.load(sys.stdin); [print(k,':',v) for k,v in d.get('scripts',{}).items()]"
```

- CLI のみのツールなら `build:cli` 相当のスクリプトで十分
- Web UI を持つツール (ブラウザを開くもの) は `build` など全体をビルドするスクリプトを使う

### 5. `bin` のエントリポイント確認

```bash
curl -s https://raw.githubusercontent.com/<owner>/<repo>/v<version>/package.json \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('bin'))"
```

### 6. `.nix` ファイルの作成

`nix/modules/npm/packages/<pname>.nix`:

```nix
{ pkgs }:
let
  version = "<x.y.z>";
  src = pkgs.fetchFromGitHub {
    owner = "<owner>";
    repo = "<repo>";
    rev = "v${version}";
    hash = "sha256-<src-hash>";
  };
  pnpmDeps = pkgs.pnpm.fetchDeps {
    pname = "<pname>";
    inherit version src;
    fetcherVersion = 1;
    hash = "sha256-<pnpm-deps-hash>";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "<pname>";
  inherit version src;
  nativeBuildInputs = [
    pkgs.nodejs_22
    pkgs.pnpm.configHook
    pkgs.makeWrapper
  ];
  inherit pnpmDeps;
  buildPhase = ''
    pnpm run build
  '';
  installPhase = ''
    mkdir -p $out/lib/<pname> $out/bin
    cp -r dist node_modules package.json $out/lib/<pname>/
    find $out/lib/<pname>/node_modules -xtype l -delete
    makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/<pname> \
      --add-flags "$out/lib/<pname>/dist/<entrypoint>.js"
  '';
}
```

**モノレポ構成の注意**: pnpm workspace でローカルパッケージへの symlink が node_modules に含まれる場合がある。`find -xtype l -delete` で broken symlink を削除すること。

### 7. フォーマットとビルド確認

```bash
nixfmt nix/modules/npm/packages/<pname>.nix
git add nix/modules/npm/
home-manager build --flake ./nix
```

### 8. 動作確認と反映

```bash
home-manager switch --flake ./nix
<pname> --help
```

## npm プロジェクト (pnpm でない) の場合

`pnpmDeps` の代わりに `buildNpmPackage` を使う:

```nix
pkgs.buildNpmPackage {
  pname = "<pname>";
  inherit version src;
  nodejs = pkgs.nodejs_22;
  npmDepsHash = "sha256-<hash>";  # 同様にダミーで取得
}
```
