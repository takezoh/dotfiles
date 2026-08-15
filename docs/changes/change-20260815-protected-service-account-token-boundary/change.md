---
id: change-20260815-protected-service-account-token-boundary
kind: change
title: Restore the protected service-account token bootstrap boundary
status: done
created: '2026-08-15'
profile: sdd@1
intent: 1Passwordを正本として保持しつつ、service-account tokenを初回だけprotected ~/.secrets境界へ取得して非対話利用を復旧する。
outcomes:
- 通常setupは有効なprotected tokenを再利用し、1Passwordを再度呼ばない。
- 初回取得と明示refreshだけが固定Personal itemを読み、成功後にatomic置換する。
- resolverは固定token pathだけを読み、固定native op childだけへ渡す。
scope:
- modules/credproxy/provision-service-account-token.sh
- modules/credproxy/setup.sh
- modules/credproxy/assets/hooks/op-resolve.py
- modules/credproxy/assets/systemd/user/credproxyd.service
- modules/credproxy/tests
- modules/credproxy/README.md
- docs/design/design-credential-integration-wiring-boundary.md
- docs/adr/adr-20260815-protected-service-account-token-boundary.md
- modules/credproxy/install.sh
- modules/credproxy/assets/config.toml
non_goals:
- service-account tokenの発行またはrotation
- systemd-credsの現時点での導入
- agent-module、context-fabric、mcp-gatewayへのcredential holder追加
change_classes:
- capability
- boundary
- invariant
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260815-protected-service-account-token-boundary/requirements.md
  required: true
- role: implementation
  path: changes/change-20260815-protected-service-account-token-boundary/implementation.md
  required: true
- role: verification
  path: changes/change-20260815-protected-service-account-token-boundary/verification.md
  required: true
evidence_refs:
- type: test
  ref: python3 -B -m unittest discover -s modules/credproxy/tests -p test_*.py (42
    tests passed)
- type: command
  ref: bash -n modules/credproxy/install.sh modules/credproxy/setup.sh modules/credproxy/provision-service-account-token.sh
- type: command
  ref: dev-docs lint --conformance
- type: command
  ref: git diff --check
- type: command
  ref: installed ctx sync succeeded and ctx doctor reported all checks ok with 39
    fresh entities
promotion:
- target: design-credential-integration-wiring-boundary
  section: responsibilities
  action: upsert
  item:
    id: RESP-001
    statement: Retrieve the stored service-account token once from 1Password into
      the protected local secret boundary, and install injection routes and OS service
      definitions without owning product semantics.
unresolved_decisions: []
tags:
- credproxy
- credential
- 1password
owners: []
relations:
- {type: introduces, target: adr-20260815-protected-service-account-token-boundary}
- {type: modifies, target: design-credential-integration-wiring-boundary}
source_paths:
- modules/credproxy
- docs/design/design-credential-integration-wiring-boundary.md
summary: Correct the host credential holder while preserving 1Password as canonical.
updated: '2026-08-15'
promotion_applied_at: '2026-08-15T04:02:16.529858+00:00'
closure:
  closed_at: '2026-08-15T04:02:23.119484+00:00'
  content_hash: sha256:511c0b099116f5f09f2bed587d49b15b83c216f039f9be0de892c3b96f87822a
---

## Summary

誤って導入したsystemd-creds前提とWSL都度取得案を撤回し、既存のprotected local
bootstrap token契約を、owner/mode/symlink検証とatomic refresh付きで復旧する。

## Closure Notes


{% transition from="draft" to="ready" date="2026-08-15" %}
Corrected contract, scope, security gates, and acceptance criteria are explicit.
{% /transition %}


{% transition from="ready" to="active" date="2026-08-15" %}
RED/GREEN implementation and repository verification are in progress.
{% /transition %}


{% transition from="active" to="closing" date="2026-08-15" %}
Protected token bootstrap, pinned shallow source acquisition, broker routing, and installed host acceptance are verified.
{% /transition %}
