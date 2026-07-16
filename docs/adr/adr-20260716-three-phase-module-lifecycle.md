---
id: adr-20260716-three-phase-module-lifecycle
kind: adr
title: Use three-phase module lifecycle
status: accepted
created: '2026-07-16'
decision_makers:
- repository owner
consequences:
  positive:
  - package installation、設定配置、更新を目的別に再実行できる。
  negative:
  - module ごとに複数 entrypoint を保守する必要がある。
  neutral:
  - profile runner が phase routing を担う。
tags: []
owners: []
relations:
- {type: introduces, target: design-environment-bootstrap}
- {type: references, target: design-shell-runtime}
source_paths: []
summary: Modules separate installation, configuration, and explicit update side effects.
updated: '2026-07-16'
---

## Context

新規環境の構築、既存環境への設定再配置、tool 更新では必要な副作用と実行頻度が異なる。

## Decision

module lifecycle を install、setup、update に分け、profile runner が要求 phase を各 module へ順序付きで渡す。env は shell load contract として別に保つ。

## Consequences

- Positive: setup だけの安全な再実行や update の明示実行が可能になる。
- Negative: module author は phase 境界を判断して複数 script を保守する。
- Neutral: root entrypoint は薄く、profile が構成を所有する。

## Alternatives

全副作用を一つの install script にまとめる案は、再実行時の影響を制御しにくいため採用しない。
