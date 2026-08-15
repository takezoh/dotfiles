---
id: change-20260814-context-fabric-owner-cutover
kind: change
title: Delegate Context Fabric runtime lifecycle to agent-module
status: done
created: '2026-08-14'
profile: sdd@1
intent: Context Fabric runtimeのsole ownerをagent-moduleへ移し、dotfilesをcredproxy authorityと明示handoffへ限定する。
outcomes:
- supported host profilesはContext Fabric runtime lifecycleをagent-module経由で一度だけ実行する。
- dotfiles adapterはcredproxy resolverのexact socketとlegacy owner absent evidenceを渡す。
- credproxy credential lifecycleとmanual operator gateはdotfilesに残る。
scope:
- modules/agent-module
- profiles/host-wsl.sh
- profiles/host-darwin.sh
- profiles/host-ubuntu-server.sh
- docs/adr/adr-20260814-delegate-context-fabric-runtime-owner.md
non_goals:
- credentialまたはprincipalの発行、暗号化、複製
- Context Fabric product config schemaの再実装
- completed changeの書換え
change_classes:
- responsibility
- boundary
- invariant
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260814-context-fabric-owner-cutover/requirements.md
  required: true
- role: implementation
  path: changes/change-20260814-context-fabric-owner-cutover/implementation.md
  required: true
- role: verification
  path: changes/change-20260814-context-fabric-owner-cutover/verification.md
  required: true
evidence_refs:
- type: test
  ref: python3 -B -m unittest discover -s modules/agent-module/tests -p test_*.py
    (3 tests passed)
- type: test
  ref: python3 -B -m unittest discover -s modules/credproxy/tests -p test_*.py (42
    tests passed)
- type: command
  ref: bash -n modules/agent-module/install.sh modules/agent-module/setup.sh modules/agent-module/update.sh
    modules/agent-module/context-fabric-handoff.sh profiles/host-wsl.sh profiles/host-darwin.sh
    profiles/host-ubuntu-server.sh
- type: command
  ref: installed ctx sync completed without error and ctx doctor reported all checks
    ok with 39 fresh entities
promotion:
- target: design-environment-bootstrap
  section: responsibilities
  action: upsert
  item:
    id: RESP-004
    statement: Dotfiles owns credproxy secure authority and passes its exact broker
      socket to the agent-module-owned Context Fabric runtime lifecycle.
unresolved_decisions: []
tags:
- context-fabric
- ownership
owners: []
relations:
- {type: references, target: adr-20260716-agent-module-boundary}
- {type: introduces, target: adr-20260814-delegate-context-fabric-runtime-owner}
source_paths: []
summary: Retire the dotfiles Context Fabric runtime module from profiles and retain
  only the credproxy handoff.
updated: '2026-08-15'
promotion_applied_at: '2026-08-15T04:11:17.624099+00:00'
closure:
  closed_at: '2026-08-15T04:11:25.384671+00:00'
  content_hash: sha256:63c091df1f7e5913a46b05d29d555eeefcf1d0afea7cf1afb951c5a21e70d42a
---

## Summary

agent-module-first rollout後、supported host profileからlegacy `context-fabric-service` moduleを退役させる。module sourceはrollback evidenceとして保持するが通常profileから呼ばない。

{% transition from="draft" to="ready" date="2026-08-14" %}
ownershipとhandoff契約を確定
{% /transition %}

{% transition from="ready" to="active" date="2026-08-15" %}
adapter/profile cutoverを実装
{% /transition %}


{% transition from="active" to="closing" date="2026-08-15" %}
Thin handoff, legacy owner retirement, credential ownership, and installed-host convergence are verified.
{% /transition %}
