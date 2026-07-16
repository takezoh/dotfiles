---
id: design-developer-tooling-modules
kind: design
title: Developer tooling modules
status: active
created: '2026-07-16'
scope_type: area
responsibilities:
- id: RESP-001
  statement: editor、CLI、SDK、container、platform bridge を独立 module として配布する。
- id: RESP-002
  statement: user-facing 操作手順を各 module の README に保持する。
invariants:
- id: INV-001
  statement: module は別 module の内部 path を直接変更せず、共有 helper と profile 経由で協調する。
  enforcement: review
boundaries:
  provides:
  - editor、utility scripts、language SDK、container tooling
  consumes:
  - profile selection と common helper
  forbidden:
  - external submodule の直接編集
  - secret や machine-local state の tracking
variability:
  fixed:
  - capability ごとの module ownership
  free:
  - module 内の具体的な tool selection
capabilities:
- id: cap:developer-tooling
  uniqueness: multiple
failure_responsibilities:
- optional module は未選択環境へ副作用を与えない。
trust_boundaries:
- tracked configuration と tool が生成する cache/state
compatibility_policies:
- module README の利用手順は runtime configuration と同期する。
tags: []
owners: []
relations: []
source_paths:
- modules/editor-nvim/nvim/README.md
- scripts/README.md
summary: Capability ownership for editor, CLI, SDK, container, and utility modules.
updated: '2026-07-16'
---

## Purpose

開発ツールの導入と設定を capability 単位へ分け、profile から必要な集合だけを選択できるようにする。

## Responsibilities

editor、CLI、SDK、Docker、terminal、platform bridge はそれぞれ自分の install/setup と設定 asset を所有する。`scripts/` は PATH 上の小さな横断 utility を所有する。

## Boundaries

永続設計は本 document、具体的なキー割当・command・plugin 一覧は module README と設定コードが正本である。

## Invariants

submodule は upstream ownership を維持し、repository 固有の変更を加えない。

## Collaboration

profile が必要性を判断し、common helper が platform 差を吸収し、module が具体的な tool を管理する。

## Failure Responsibility

個別 tool の導入失敗を module 外へ波及させず、原因と remediation を明示する。

## Variability

tool の置換は module 内で可能。外部 observable な symlink/path contract を変える場合は migration を用意する。

## Conformance

module setup、設定ファイルの load、主要 editor/CLI の smoke test で確認する。

## Related Decisions

- `adr-20260716-three-phase-module-lifecycle`
