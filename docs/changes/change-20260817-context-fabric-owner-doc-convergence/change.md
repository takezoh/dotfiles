---
id: change-20260817-context-fabric-owner-doc-convergence
kind: change
title: Converge the Context Fabric runtime ownership boundary
status: done
created: '2026-08-17'
profile: sdd@1
intent: accepted owner cutover 後も current credproxy documentation に残った retired Context
  Fabric runtime owner 記述を収束させる。
outcomes:
- Current README and active design name agent-module as Context Fabric runtime/service
  lifecycle owner.
- Dotfiles remains limited to credproxy authority and explicit socket handoff.
scope:
- modules/credproxy/README.md
- modules/credproxy/tests/test_responsibility_boundary.py
- docs/design/design-credential-integration-wiring-boundary.md
- docs/changes/change-20260817-context-fabric-owner-doc-convergence
non_goals:
- Legacy rollback historyやcompleted changeの書き換え。
- Context Fabric runtime、config、principal、sync semanticsの所有。
change_classes:
- responsibility
- boundary
- internal_design
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260817-context-fabric-owner-doc-convergence/requirements.md
  required: true
- role: implementation
  path: changes/change-20260817-context-fabric-owner-doc-convergence/implementation.md
  required: true
- role: verification
  path: changes/change-20260817-context-fabric-owner-doc-convergence/verification.md
  required: true
promotion:
- target: design-credential-integration-wiring-boundary
  section: responsibilities
  action: upsert
  item:
    id: RESP-003
    statement: Provide the exact broker socket handoff to the agent-module-owned Context
      Fabric runtime without owning its lifecycle or product configuration.
unresolved_decisions: []
tags: []
owners: []
relations:
- {type: references, target: adr-20260814-delegate-context-fabric-runtime-owner}
- {type: modifies, target: design-credential-integration-wiring-boundary}
evidence_refs:
- type: test
  ref: python3 -B -m unittest discover -s modules/credproxy/tests -p test_*.py (44
    passed)
- type: command
  ref: dev-docs lint --conformance
source_paths:
- modules/credproxy/README.md
- modules/credproxy/tests/test_responsibility_boundary.py
- docs/design/design-credential-integration-wiring-boundary.md
summary: Dotfiles owns credential authority and exact socket handoff, not the Context
  Fabric runtime lifecycle.
updated: '2026-08-17'
promotion_applied_at: '2026-08-17T11:23:54.366405+00:00'
closure:
  closed_at: '2026-08-17T11:23:58.019091+00:00'
  content_hash: sha256:5370a6fd2f68812607dee1e2ffa8d802b9edc93744feb13113c7ca1a64c4dc6d
---

## Summary

Remove current-state claims that the retired context-fabric-service module owns runtime lifecycle while preserving historical rollback records.

## Closure Notes


{% transition from="draft" to="ready" date="2026-08-17" %}
Requirements and ownership boundaries are reviewed.
{% /transition %}


{% transition from="ready" to="active" date="2026-08-17" %}
Implementation and regression gates are complete.
{% /transition %}


{% transition from="active" to="closing" date="2026-08-17" %}
Repository gates, installed-host verification where applicable, and dev-evidence preflight passed.
{% /transition %}
