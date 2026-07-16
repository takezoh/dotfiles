---
id: design-environment-bootstrap
kind: design
title: Environment bootstrap and profiles
status: active
created: '2026-07-16'
scope_type: system
responsibilities:
- id: RESP-001
  statement: OS と利用形態に応じた module 集合と実行順序を profile で定義する。
- id: RESP-002
  statement: install、setup、update の phase を共通 runner から各 module へ伝播する。
- id: RESP-003
  statement: 設定ファイルを repository からユーザー環境へ冪等に配置する。
invariants:
- id: INV-001
  statement: install と setup は再実行可能でなければならない。
  enforcement: review
- id: INV-002
  statement: external 配下は submodule として扱い、上流 asset を直接変更しない。
  enforcement: contract
boundaries:
  provides:
  - platform profile と module lifecycle
  - shell、editor、CLI、SDK、container toolchain の配置
  consumes:
  - OS package manager と外部 tool installer
  - sibling agent-module の agent toolchain entrypoint
  forbidden:
  - secret value の repository 保存
  - agent plugin/runtime asset の直接所有
variability:
  fixed:
  - profile が module 選択と順序を所有すること
  - module が phase-specific script を所有すること
  free:
  - profile ごとの module 集合
  - platform ごとの package installation method
capabilities:
- id: cap:environment-bootstrap
  uniqueness: per-platform
- id: cap:configuration-linking
  uniqueness: per-boundary
failure_responsibilities:
- module は依存 command 不在と設定配置失敗を明示する。
trust_boundaries:
- repository asset とホームディレクトリの実設定
- dotfiles と外部 package manager/submodule
compatibility_policies:
- env.sh は POSIX shell 互換を保ち、bash と zsh の双方から読み込めるようにする。
tags: []
owners: []
relations: []
source_paths:
- profiles/_run.sh
- modules/_lib/common.sh
summary: Profile-driven, three-phase bootstrap for reproducible developer environments.
updated: '2026-07-16'
---

## Purpose

複数 platform へ同じ責務分割で開発環境を構築しつつ、環境差を profile と module の境界に閉じ込める。

## Responsibilities

root entrypoint が platform/profile を選び、`profiles/_run.sh` が phase を解釈し、各 module が自分の install/setup/env/update を実行する。

## Boundaries

dotfiles は一般的な開発環境を所有する。agent CLI・plugin・MCP/LSP の実装は sibling `agent-module` が所有し、dotfiles には薄い entrypoint だけを置く。

## Invariants

- `install.sh` は既存 command を検査して冪等に振る舞う。
- `setup.sh` は管理対象 symlink/merge だけを更新する。
- `update` は通常の all phase へ暗黙に含めない。

## Collaboration

profile が orchestration、module が capability、`modules/_lib/common.sh` が platform/helper contract を担う。

## Failure Responsibility

一つの module が失敗した場合、別 module が生成物を推測して補完しない。失敗した phase と module を呼び出し元へ返す。

## Variability

新 platform は profile、新 capability は module として追加する。既存 module 内へ無関係な platform 分岐を蓄積しない。

## Conformance

各 profile の phase 実行と module tests、shell syntax check で確認する。

## Related Decisions

- `adr-20260716-three-phase-module-lifecycle`
- `adr-20260716-agent-module-boundary`
