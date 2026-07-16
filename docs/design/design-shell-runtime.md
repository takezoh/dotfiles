---
id: design-shell-runtime
kind: design
title: Shell runtime configuration
status: active
created: '2026-07-16'
scope_type: area
responsibilities:
- id: RESP-001
  statement: zshenv、zshrc、zlogin の phase ごとに shell 初期化責任を分離する。
- id: RESP-002
  statement: 数字 prefix と local override により決定的な読み込み順を提供する。
invariants:
- id: INV-001
  statement: 非対話 shell で対話専用初期化を実行しない。
  enforcement: review
- id: INV-002
  statement: completion と plugin の順序制約を維持する。
  enforcement: conformance
boundaries:
  provides:
  - shell environment、interactive behavior、login initialization
  - machine-local override seam
  consumes:
  - external zsh plugins と lazyenv
  forbidden:
  - repository に machine-local secret を置くこと
  - zshenv で重い対話初期化を行うこと
variability:
  fixed:
  - phase ordering と rc.d の数字順
  - compinit、fzf-tab、autosuggestions、syntax-highlighting の相対順
  free:
  - local override の内容
  - 任意 tool の遅延初期化
capabilities:
- id: cap:shell-runtime
  uniqueness: per-platform
failure_responsibilities:
- optional tool がない場合は shell 全体を壊さず、その integration だけを無効化する。
trust_boundaries:
- tracked rc.d と `~/.local/config/<phase>/` の local override
compatibility_policies:
- zshenv に置く環境設定は非対話 shell でも安全にする。
tags: []
owners: []
relations: []
source_paths:
- modules/shell/zsh/README.md
- modules/shell/zsh/_zsh.load
summary: Ordered zsh phase loading, local override seams, and plugin initialization
  constraints.
---

## Purpose

shell 起動時間と機能依存を制御し、共通設定と machine-local override を予測可能な順序で合成する。

## Responsibilities

`_zsh.load <phase>` が tracked rc.d と local override を順に source し、lazyenv が高コストな language runtime 初期化を初回利用まで遅延する。

## Boundaries

zshenv は環境、zshrc は対話動作、zlogin は completion/prompt/plugin を所有する。

## Invariants

`.` prefix は無効化、数字 prefix は順序、local config は最後の override という意味を維持する。

## Collaboration

bootstrap が DOTFILES_DIR/XDG/platform helper を提供し、各 rc.d file は一つの tool integration に集中する。

## Failure Responsibility

optional integration は command existence を確認し、欠落時に shell startup を停止させない。

## Variability

tool 追加は適切な phase と番号帯で行い、platform-specific behavior は限定 directory に置く。

## Conformance

interactive/non-interactive/login shell の起動確認と zsh syntax check で検証する。

## Related Decisions

- `adr-20260716-three-phase-module-lifecycle`
