---
id: adr-20260716-agent-module-boundary
kind: adr
title: Keep agent configuration outside dotfiles
status: accepted
created: '2026-07-16'
decision_makers:
- repository owner
consequences:
  positive:
  - dotfiles の一般環境責務と agent toolchain の更新を分離できる。
  negative:
  - sibling repository の存在と接続設定が必要になる。
  neutral:
  - dotfiles は end-user profile の入口を維持する。
tags: []
owners: []
relations:
- {type: references, target: design-environment-bootstrap}
source_paths: []
summary: Agent toolchain implementation stays in a sibling repository behind a thin
  module adapter.
updated: '2026-07-16'
---

## Context

agent CLI と plugin は host vendor、permission、MCP、LSP など独自の更新境界を持ち、shell/editor/SDK と同じ repository で保守すると責務が肥大化する。

## Decision

agent 関連実装は sibling `agent-module` に置き、dotfiles の `modules/agent-module/` は DOTFILES_DIR と phase を渡す薄い adapter とする。

## Consequences

- Positive: agent toolchain を独立して進化させられる。
- Negative: clone/layout の前提と repository 間 contract が増える。
- Neutral: profile から見た module lifecycle は他 module と同じである。

## Alternatives

agent asset を dotfiles に再統合する案は ownership 分離を失うため採用しない。
