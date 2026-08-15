---
id: design-credential-integration-wiring-boundary
kind: design
title: Credential integration wiring boundary
status: active
created: '2026-08-12'
scope_type: component
responsibilities:
- id: RESP-001
  statement: Retrieve the stored service-account token once from 1Password into the
    protected local secret boundary, and install injection routes and OS service definitions
    without owning product semantics.
- id: RESP-002
  statement: Reconcile legacy shell supply without deleting unknown user state.
invariants:
- id: INV-001
  statement: dotfiles credential wiring contains no consumer executable, argv, subcommand,
    consumer source revision, or process admission policy. A pinned credproxy bootstrap
    revision identifies the broker being installed and is not consumer admission.
  enforcement: test
- id: INV-002
  statement: Context Fabric sync is wired only as POST /v1/sync/remote header injection.
  enforcement: test
boundaries:
  provides:
  - installed credproxyd configuration and authority resolver
  - atomic 1Password-to-protected-local-secret provisioning on Linux and WSL
  - separate context-fabric-service and credproxyd lifecycles
  - explicit local deployment paths passed through the Context Fabric public initializer
  - legacy profile reconciliation
  consumes:
  - credproxy protocol injection contract
  - Context Fabric HTTP sync contract
  - fixed 1Password Personal item
  - a human-authenticated 1Password CLI for initial provisioning or explicit refresh
  forbidden:
  - owning Context Fabric sync semantics
  - rendering Context Fabric JSON or provisioning a principal credential
  - issuing or rotating the 1Password service-account token
  - persisting credential material outside ~/.secrets/op/service-account.token
  - using external repository commits, hook digests, or consumer commands as route
    admission
variability:
  fixed:
  - exact HTTP method/path/upstream and injected header name
  - no persistent credential fallback outside the protected ~/.secrets boundary
  - fixed 1Password source reference and platform-explicit authority selection
  free:
  - OS service packaging details
capabilities:
- id: cap:credential-integration-wiring
  uniqueness: per-boundary
failure_responsibilities:
- Missing initial 1Password access, invalid protected token authority, context-service
  health, or managed provenance disables the route and preserves the previous valid
  token and legacy state.
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
- modules/context-fabric-service
summary: dotfiles owns secure authority and service wiring without consumer command
  policy or source revision admission.
---

## Purpose

Wire credential producers and protocol consumers without becoming either product's
operation-policy owner.

## Responsibilities

Install copies, render route configuration, manage each OS service in its owning
module, and migrate known dotfiles state. Context Fabric config remains opaque and
product-owned.

## Boundaries

credproxy owns injection; Context Fabric owns sync. dotfiles connects their public
protocols.

## Invariants

No consumer repository SHA, hook digest, executable allowlist, argv grammar, or closed
operation appears in production route wiring. Fresh-host source acquisition separately
verifies the reviewed credproxy bootstrap revision before checking out or building it.

## Collaboration

`POST /v1/sync/remote` and `Authorization` are the complete integration contract.
Before service start, dotfiles invokes the installed `ctx service init` with the
installed client snapshot, one explicit deployment tenant, and absolute local paths.
The product CLI, not dotfiles, owns JSON projection and validation.

## Failure Responsibility

Setup fails closed and never substitutes parent env or a request-selected file.
Credential refresh stages an owner-only token file inside `~/.secrets/op` and commits
it atomically only after the 1Password read succeeds.

## Variability

Linux/WSL protected local secret and macOS Keychain packaging may differ while the
route contract remains identical. A future systemd-creds holder changes neither the
1Password canonical source nor the bootstrap-token semantics.

## Conformance

`python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'`.

## Related Decisions

- `adr-20260812-keep-consumer-operations-out-of-dotfiles`
