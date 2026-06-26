---
name: domain-design-safety-discipline
description: ドメインモデル、可視性、操作可能性、不変条件、層境界、API 設計に関わる実装時に使う。不正な状態や誤った呼び出し方を型・関数境界・ドメイン語彙で表現し、正しい使い方が自然になる設計へ寄せるためのスキル。
---

# 安全なドメイン設計の規律

## 基本方針

正しい使い方が自然になり、誤った使い方が書きにくい設計を優先する。

呼び出し側の注意力、コメント、ドキュメント、テストだけに依存しない。暗黙の順序、事前チェック、validation 済みであることは、可能な限り型、関数、戻り値、境界で表現する。

## 正しい使い方が自然になる API

避けるもの:

- 特定の順番で呼ばないと壊れる API
- 呼び出し前に別の関数でチェックが必要な API
- 不正な状態を作れてしまう struct / enum
- `bool` や primitive の組み合わせで意味を推測させる API
- コメントで注意しないと危険な public method

考えること:

- 事前チェックを生成関数や constructor に寄せられないか
- 戻り値で次に可能な操作を制限できないか
- enum の variant で状態を分け、不正な組み合わせを消せないか
- private field と public constructor で不変条件を守れないか

## Always-valid model

ドメイン上ありえない状態は、可能な限り型で表現できないようにする。

- validation を handler や usecase に散らさない
- 値オブジェクト、集約、生成関数、domain service に不変条件を寄せる
- `String` / `Vec` / primitive 型をそのまま使う前に、ドメイン制約を持つ型にできないか考える
- 「作った後にチェックする」より、「チェック済みの値しか作れない」形を優先する
- ただし、意味の薄い wrapper 型や 1 箇所でしか価値のない型を増やしすぎない

判断基準:

- その型は不正状態を実際に消しているか
- その型名はドメイン語彙として意味があるか
- その validation は複数箇所へ散らばる可能性があるか
- テストや呼び出し側の注意を減らしているか

## 可視性・操作可能性

可視性や操作可能性を、最初から application 層の手続きとして扱うとは限らない。

「誰が見えてよいか」「誰が操作してよいか」「どの状態なら操作できるか」は、単なる外側の制御ではなくドメイン仕様であることが多い。handler や usecase に条件分岐を書く前に、それがドメインの言葉で説明できるルールかを確認する。

避けるもの:

- handler / controller だけで可視性や操作可否の判断を完結させる
- usecase の末端で取得結果を削るだけにする
- presentation 層に「見えてよいか」「操作してよいか」の判断を漏らす
- 可視性や操作可否の漏れをテストだけで防ごうとする
- 取得後に filter するだけで、本来取得してはいけないデータを扱う

考えること:

- そのルールは application 層の制御か、ドメイン上の制約か
- ドメイン仕様なら、集約、domain service、policy、query model のどこで表現するのが自然か
- 操作可能な状態と操作不能な状態を、型や戻り値で区別できないか
- repository / query の段階で可視性条件を表現すべきか
- 操作の前提条件を呼び出し側の記憶に頼らない API にできないか

## ドメイン語彙で操作を表す

ドメイン上の操作は、できるだけドメインの言葉で表現する。

望ましい例:

- `post_message`
- `submit_answer`
- `publish`
- `archive`
- `invite_member`
- `mark_as_read`

避けたい例:

- `update_xxx_field`
- `set_status`
- `modify_record`
- `apply_flag`

外側の usecase に手続きが散らばっている場合、その操作は集約や domain service のメソッドとして表現できないか考える。

ただし、巨大な集約を無理に全部ロードしてまで自然なメソッド形にしない。整合性境界と性能上の境界は分けて考える。

## 層境界と型の流出

境界を越える型を混ぜない。

- infra の型を domain / application に漏らさない
- DB entity、HTTP request / response、外部 API DTO は境界で変換する
- usecase を presentation 都合の response shape に寄せすぎない
- presentation 層にドメイン判断、可視性判断、永続化都合を漏らさない
- mapping は面倒でも、境界を明確にするために分離する

判断基準:

- この型はどの層の都合を表しているか
- 外部 API や DB schema の変更が domain に波及しないか
- presentation の表示都合が usecase や domain に入り込んでいないか
- mapping を省いたことで、境界が曖昧になっていないか

## セルフレビュー

実装後、差分を見て確認する。

- 不正な状態を作れる struct / enum が増えていないか
- validation が handler / usecase に散らばっていないか
- `String` / `Vec` / primitive をそのまま使った箇所に、ドメイン制約が隠れていないか
- 呼び出し側が「この順番で呼ぶ」「先にチェックする」ことを覚える必要がないか
- 可視性・操作可能性を application 層の手続きとして決めつけていないか
- 可視性・操作可能性が presentation 層に漏れていないか
- infra / DB / HTTP / external DTO が domain や application に漏れていないか
- ドメイン操作が技術的な setter / updater 名に寄りすぎていないか
- wrapper 型や abstraction を増やしすぎていないか
- 整合性境界と性能上の境界を混同していないか

問題が見つかった場合は修正し、もう一度このレビューを行う。
