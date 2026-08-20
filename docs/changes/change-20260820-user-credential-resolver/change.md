---
id: change-20260820-user-credential-resolver
kind: change
title: Move 1Password access to the user credential resolver
status: active
created: '2026-08-20'
profile: sdd@1
intent: Preserve credproxy's generic credential-command boundary while preventing
  runtime token environment export and interactive 1Password invocation.
outcomes:
- credproxy has no 1Password-specific provider or dependency.
- A dotfiles-owned resolver reads the protected token file and uses the 1Password
  SDK.
- Users can replace the resolver command for another credential manager.
scope:
- modules/credproxy resolver, config, install/setup lifecycle, tests, and documentation
non_goals:
- defining a universal credential-manager plugin schema beyond the existing command
  contract
- rotating or changing the fixed 1Password items
change_classes:
- responsibility
- boundary
- dependency
governance:
  gate: hard
  reasons:
  - Changes the credential authority responsibility boundary.
  approval_evidence: User explicitly directed that 1Password access belongs in the
    user script and must remain replaceable on 2026-08-20.
members:
- role: requirements
  path: changes/change-20260820-user-credential-resolver/requirements.md
  required: true
- role: implementation
  path: changes/change-20260820-user-credential-resolver/implementation.md
  required: true
- role: verification
  path: changes/change-20260820-user-credential-resolver/verification.md
  required: true
promotion: []
unresolved_decisions: []
tags: []
owners: []
relations:
- {type: modifies, target: design-credential-integration-wiring-boundary}
- {type: introduces, target: adr-20260820-user-owned-credential-resolvers}
- {type: supersedes, target: change-20260820-onepassword-sdk-runtime}
source_paths:
- modules/credproxy
summary: Keep credproxy provider-neutral and resolve protected-file credentials in
  the user-owned credential command.
updated: '2026-08-20'
---

## Summary

Retain `credential_command` as the broker boundary. Build a user-owned resolver
that reads the protected bootstrap token and calls the 1Password SDK without
environment or CLI delivery.

## Closure Notes


{% transition from="draft" to="ready" date="2026-08-20" %}
Requirements, responsibility ADR, implementation boundary, and verification contract are complete.
{% /transition %}


{% transition from="ready" to="active" date="2026-08-20" %}
Resolver implementation and verification are in progress.
{% /transition %}
