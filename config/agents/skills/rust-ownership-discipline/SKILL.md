---
name: rust-ownership-discipline
description: Rust のコードを書く・直す・レビューするときに使う。所有権、借用、Clone/Copy derive、文字列型 (`String`, `&str`, `Cow`, `'static str`) の選び方を、安易な複製や過剰な lifetime 固定に寄せず、実際のデータ所有者と呼び出し境界に合わせて判断するためのスキル。
---

# Rust の所有権判断の規律

## 基本方針

Rust では、所有権と lifetime を「コンパイルを通すための飾り」ではなく、データの責務境界として扱う。

まず自然な所有者、借用で済む範囲、値を複製する理由を確認する。`Clone` / `Copy` / `'static` は便利だから付けるのではなく、API とデータの寿命を正しく表す場合だけ使う。

このスキルは、The Rust Book、標準ライブラリ docs、Rust API Guidelines、Clippy の所有権関連 lint から実装判断に必要な部分だけを蒸留したものとして扱う。通常の実装やレビューでは外部 URL を読みに行かず、この本文の判断基準を使う。Rust の仕様変更や判断基準そのものを更新するときだけ、元資料を確認する。

## Clone / Copy derive

`Clone` / `Copy` を derive する前に、その型の意味で複製が自然かを確認する。

`Copy` は、代入や引数渡しで move ではなく安い複製になることを API として公開する。実装できる型は基本的に `Copy` にしてよいが、将来 `Copy` でなくなる可能性がある公開型では、破壊的変更を避けるために省く判断も妥当。

`Copy` を許可しやすい型:

- `u64` や `Uuid` などの小さな値に意味を付けるだけの newtype
- 座標、サイズ、期間、フラグのように値そのものが小さく、複製しても同じ概念を表す値オブジェクト
- 所有権移動を意識させるほうが不自然な、単純で不変な識別子

`Copy` にしてはいけない型:

- `Drop` を実装する型、または将来リソース解放を持つ可能性が高い型
- `String`、`Vec<T>`、`PathBuf`、`OsString`、file handle、socket、lock guard など、heap buffer や外部リソースの管理責任を持つ型
- `&mut T` を含む型。mutable reference の複製は aliasing ルールに反する

`Clone` を安易に derive しない型:

- 集約 struct、状態を持つ domain object、外部リソースや大きな `Vec` / `String` を含む型
- 複製すると「別インスタンスなのか、同じもののコピーなのか」が曖昧になる型
- 呼び出し側の所有権設計を避けるためだけに clone されている型

必要になってから `Clone` を足す。足す場合も、呼び出し側で本当に別の所有値が必要か、借用や参照渡しで表せないかを先に確認する。`clone()` は heap data の複製や任意の処理を伴いうるため、可視的なコストとして扱う。

```rust
// OK: 値そのものが識別子で、複製しても責務が増えない。
#[derive(Clone, Copy, Debug, Eq, PartialEq, Hash)]
struct UserId(u64);

// 要確認: clone で同じ集約のコピーを作る意味が曖昧になりやすい。
#[derive(Clone)]
struct User {
    id: UserId,
    name: String,
    permissions: Vec<String>,
}
```

## 文字列型

文字列は、誰が所有し、どれくらい生きるかで選ぶ。

- 値として保持する struct field は、通常 `String` を使う
- 一時的に読むだけの関数引数は、通常 `&str` を受け取る
- literal やプロセス全体で固定の定数だけを表す場合に限り、`&'static str` を使う
- borrowed と owned の両方を自然に受けたい場合だけ、`Cow<'a, str>` や generic を検討する

`'static str` は「長く生きてほしい文字列」ではない。設定値、入力、DB/API 由来の値、後から組み立てる値を `'static` に寄せない。必要なら所有する `String` にする。

型選択の初期値:

| 場面 | まず選ぶ型 | 理由 |
|---|---|---|
| struct が値を保持する | `String` | 所有者が明確で、不要な lifetime を API 外へ漏らさない |
| 関数が一時的に読む | `&str` | `String`、`&str`、slice 由来の値を広く受けられる |
| 固定メッセージや定数 | `&'static str` | binary に埋め込まれた literal の寿命を正しく表す |
| 必要なら借用、必要なら所有 | `Cow<'a, str>` | mutation や所有が必要なときだけ clone できる |
| 複数 thread で同じ文字列を共有 | `Arc<str>` | 所有値を共有し、文字列本体の重複を避ける |

```rust
// OK: 入力を読むだけなら &str。
fn normalize_name(name: &str) -> String {
    name.trim().to_lowercase()
}

// OK: 設定値を保持する型は所有する。
struct Config {
    profile_name: String,
}

// 避ける: 呼び出し側に String を強制する理由がない。
fn normalize_name_bad(name: &String) -> String {
    name.trim().to_lowercase()
}
```

`Path` / `PathBuf`、`OsStr` / `OsString`、slice / `Vec<T>` でも同じ考え方を使う。読むだけの引数は借用型、保持する field や返り値は所有型を基本にする。

## 実装時の確認

Rust の差分を書いた後、次を確認する。

- `Clone` / `Copy` derive が、型の意味として自然か
- `.clone()` が、所有値を本当に複数箇所で持つ必要から出ているか
- clone で borrow checker との向き合いを避けていないか
- struct field に `&str` や `&'static str` を入れて、不要に lifetime を外へ漏らしていないか
- API が呼び出し側に不自然な lifetime や所有権を強制していないか
- `String` を使えば素直な箇所を、過剰に `&'static str`、generic、`Cow` へ寄せていないか

迷う場合は、まず所有する `String` と借りる `&str` の素直な形で書く。性能上の理由や API 境界の理由が具体的に出てから、より細かい型へ寄せる。

## 出典メモ

この節はスキル更新時の確認先であり、通常の実装中に毎回読む必要はない。

- The Rust Book: ownership、references and borrowing、`String` / `Clone` / `Copy` の基本
- `std::marker::Copy`: `Copy` にできない型、`Copy` が public API であること
- `std::borrow::Cow`: clone-on-write と borrowed / owned の使い分け
- `std::string::String`: `String` の heap buffer、length、capacity
- Rust API Guidelines: 標準 conversion trait と予測しやすい API 設計
- Clippy `ptr_arg` / `redundant_clone`: `&String` より `&str`、不要な clone の検出
