---
id: change-20260813-context-runtime-boundary
kind: change
title: Separate Context Fabric service lifecycle from credential proxy wiring
status: done
created: '2026-08-13'
profile: sdd@1
intent: Context Fabric local service と credential proxy の install/setup責務を分離し、端末setupが責務空白なくfail
  closedで収束するようにする。
outcomes:
- Context Fabric service は専用moduleがatomic installed copyとOS lifecycleを所有する。
- credproxy moduleはbroker、secure authority、protocol routeだけを所有する。
- Linux/WSL/macOSでrendered broker socketとservice lifecycleが同じpathを使う。
scope:
- modules/context-fabric-service
- modules/credproxy
- profiles/host-wsl.sh
- profiles/host-darwin.sh
- profiles/host-ubuntu-server.sh
- docs/design/design-credential-integration-wiring-boundary.md
non_goals:
- Context Fabric service config schemaまたは値の生成
- credential、principal、remote sync semanticsのprovisioning
- agent-moduleのplugin distribution変更
change_classes:
- responsibility
- boundary
- invariant
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260813-context-runtime-boundary/requirements.md
  required: true
- role: implementation
  path: changes/change-20260813-context-runtime-boundary/implementation.md
  required: true
- role: verification
  path: changes/change-20260813-context-runtime-boundary/verification.md
  required: true
evidence_refs:
- type: command
  ref: python3 -m unittest discover -s modules/context-fabric-service/tests -p 'test_*.py'
    (9 tests OK)
- type: command
  ref: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py' (35
    tests OK)
- type: command
  ref: bash -n modules/context-fabric-service/install.sh modules/context-fabric-service/setup.sh
    modules/context-fabric-service/update.sh modules/credproxy/install.sh modules/credproxy/setup.sh
    modules/credproxy/update.sh modules/credproxy/socket-path.sh
- type: command
  ref: python3 /home/take/.codex/plugins/cache/agent-module-dev/dev/0.2.0/skills/dev-docs/scripts/docs_cli.py
    lint --conformance
- type: command
  ref: git diff --check
promotion:
- target: design-credential-integration-wiring-boundary
  section: responsibilities
  action: upsert
  item:
    id: RESP-001
    statement: Install secure credential authority, Context Fabric runtime copies,
      injection routes, and OS service definitions without owning product semantics.
unresolved_decisions: []
tags: []
owners: []
relations: []
source_paths: []
summary: Context Fabric service lifecycleをcredproxyから分離し、installed copy、OS service、secure
  routeの責務を明確化する。
updated: '2026-08-13'
promotion_applied_at: '2026-08-13T08:42:40.101264+00:00'
closure:
  closed_at: '2026-08-13T08:43:00.939830+00:00'
  content_hash: sha256:6f85926bb6fcb90f8ebeab0941a0937d652c0d0e9a5c7fe151646887437295a2
---

## Summary

Context Fabric service lifecycleをcredproxy moduleから独立させ、product configを
opaque inputとして消費する専用moduleへ移す。broker socketはplatformごとに一度だけ
解決し、credential authorityが使えない場合はbrokerを無効化する。

## Closure Notes

Context Fabric service lifecycleを専用moduleへ分離し、public initializer、installed
client snapshot、明示absolute paths、platform共通socket resolverによるsetup契約を
実装した。credential proxyはbroker、secure authority、HTTP injection routeだけを
所有する。


{% transition from="draft" to="ready" date="2026-08-13" %}
要件・実装計画・verificationを確定
{% /transition %}


{% transition from="ready" to="active" date="2026-08-13" %}
責務境界の実装を実施
{% /transition %}


{% transition from="active" to="closing" date="2026-08-13" %}
実装、境界テスト、文書conformanceが完了
{% /transition %}
