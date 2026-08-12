---
id: design-credential-integration-wiring-boundary
kind: design
title: Credential integration wiring boundary
status: active
created: '2026-08-12'
scope_type: component
responsibilities:
- id: RESP-001
  statement: Install secure credential authority, credproxy injection routes, and
    service definitions.
- id: RESP-002
  statement: Reconcile legacy shell supply without deleting unknown user state.
invariants:
- id: INV-001
  statement: dotfiles credential wiring contains no consumer executable, argv, subcommand,
    source revision, or process admission policy.
  enforcement: test
- id: INV-002
  statement: Context Fabric sync is wired only as POST /v1/sync/remote header injection.
  enforcement: test
boundaries:
  provides:
  - installed credproxyd configuration and authority resolver
  - service lifecycle and legacy profile reconciliation
  consumes:
  - credproxy protocol injection contract
  - Context Fabric HTTP sync contract
  forbidden:
  - owning Context Fabric sync semantics
  - validating external repository commits, hook digests, or consumer commands
variability:
  fixed:
  - exact HTTP method/path/upstream and injected header name
  - absence of persistent plaintext credential fallback
  free:
  - OS service packaging details
capabilities:
- id: cap:credential-integration-wiring
  uniqueness: per-boundary
failure_responsibilities:
- Missing authority, context-service health, or managed provenance disables the route
  and preserves legacy state.
trust_boundaries:
- OS secure credential authority to credproxyd provider helper
- credproxyd HTTP injection to context-service
compatibility_policies:
- Unknown user-managed files are preserved and reported as conflicting.
tags: []
owners: []
relations: []
source_paths:
- modules/credproxy
summary: dotfiles owns secure authority and service wiring without consumer command
  policy or source revision admission.
---

## Purpose

Wire credential producers and protocol consumers without becoming either product's
operation-policy owner.

## Responsibilities

Install copies, render route configuration, manage services, and migrate known
dotfiles state.

## Boundaries

credproxy owns injection; Context Fabric owns sync. dotfiles connects their public
protocols.

## Invariants

No repository SHA, hook digest, executable allowlist, argv grammar, or closed
operation appears in production wiring.

## Collaboration

`POST /v1/sync/remote` and `Authorization` are the complete integration contract.

## Failure Responsibility

Setup fails closed and never substitutes parent env or plaintext files.

## Variability

systemd and launchd may differ while the route contract remains identical.

## Conformance

`python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'`.

## Related Decisions

- `adr-20260812-keep-consumer-operations-out-of-dotfiles`
