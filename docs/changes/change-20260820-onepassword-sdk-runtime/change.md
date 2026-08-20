---
id: change-20260820-onepassword-sdk-runtime
kind: change
title: Use the 1Password SDK without credential environment export
status: abandoned
created: '2026-08-20'
profile: sdd@1
intent: Prevent Context Fabric sync from launching interactive 1Password by removing
  runtime CLI and credential-environment delivery.
outcomes:
- credproxyd resolves fixed 1Password references with the official SDK in-process.
- The service-account token is read only from ~/.secrets/op/service-account.token.
- Runtime wiring contains no token environment export, op helper, or WSL PATH injection.
scope:
- modules/credproxy runtime config, install/setup lifecycle, tests, and documentation
non_goals:
- changing the fixed 1Password items or rotating their credentials
- removing the setup-time interactive CLI used for initial provisioning or explicit
  refresh
change_classes:
- boundary
- dependency
governance:
  gate: hard
  reasons:
  - Modifies the credential authority boundary and supersedes accepted ADRs.
  approval_evidence: User explicitly requested the fix and prohibited service-account
    token environment delivery on 2026-08-20.
members:
- role: requirements
  path: changes/change-20260820-onepassword-sdk-runtime/requirements.md
  required: true
- role: implementation
  path: changes/change-20260820-onepassword-sdk-runtime/implementation.md
  required: true
- role: verification
  path: changes/change-20260820-onepassword-sdk-runtime/verification.md
  required: true
promotion: []
unresolved_decisions: []
tags: []
owners: []
relations:
- {type: modifies, target: design-credential-integration-wiring-boundary}
- {type: introduces, target: adr-20260820-in-process-onepassword-sdk}
source_paths:
- modules/credproxy
summary: Replace the runtime op helper with direct in-process SDK resolution from
  the protected token file.
updated: '2026-08-20'
---

## Summary

The prior resolver put the protected token in `OP_SERVICE_ACCOUNT_TOKEN` for an
`op` child. Replace that runtime path with the credproxy direct SDK provider and
retain the CLI only at the explicit provisioning boundary.

## Closure Notes


{% transition from="draft" to="ready" date="2026-08-20" %}
Requirements, implementation boundary, ADR, and verification contract are complete.
{% /transition %}


{% transition from="ready" to="active" date="2026-08-20" %}
Implementation and host cutover are in progress.
{% /transition %}


{% transition from="active" to="abandoned" date="2026-08-20" %}
User corrected the responsibility boundary: credential backend access belongs in a user-owned credential command, not credproxyd.
{% /transition %}
