---
id: adr-20260815-provision-systemd-credential-from-1password
kind: adr
title: Provision systemd credential from the stored 1Password token
status: superseded
created: '2026-08-15'
decision_makers:
- takezoh
confirmation: python3 -m unittest modules.credproxy.tests.test_systemd_credential_provision
consequences:
  positive:
  - The 1Password item remains the source of truth while no plaintext token is persisted
    locally.
  negative:
  - Linux provisioning requires an authenticated interactive op CLI and systemd-creds
    user-scoped encryption support.
  neutral:
  - Service-account issuance and rotation remain operator actions in 1Password.
tags:
- credproxy
- credential
- systemd
owners: []
relations:
- {type: references, target: adr-20260812-keep-consumer-operations-out-of-dotfiles}
source_paths:
- modules/credproxy
summary: Dotfiles retrieves the fixed 1Password item and converts it directly to a
  user-scoped systemd encrypted credential without a persistent plaintext copy.
updated: '2026-08-15'
---

## Context

The previous migration removed the retrieval of a service-account token already
stored in 1Password and replaced it with an operator-created encrypted blob. On a
host without a usable provisioning path this left credproxyd permanently disabled,
even though the authoritative token still existed in 1Password.

## Decision

Dotfiles owns the conversion boundary on Linux/WSL. It reads exactly one fixed
1Password Personal item and pipes the token directly to `systemd-creds --user
encrypt`. The plaintext may exist only in the pipe between these two fixed tools;
it is never assigned to a shell variable, argv, persistent file, log, or evidence.

Setup provisions only when the encrypted credential is absent. Explicit
`--refresh` stages new ciphertext beside the installed credential and atomically
replaces it only after the source read and encryption both succeed. Unknown paths,
symlinks, owners, or modes are conflicting and are never overwritten.

Dotfiles does not issue or rotate the 1Password service account and does not issue
or rotate a Context Fabric principal.

## Consequences

{% consequence kind="positive" %}
The existing 1Password item is again consumable without restoring the legacy
plaintext token file.
{% /consequence %}

{% consequence kind="negative" %}
Unsupported systemd versions and locked or unavailable 1Password sessions keep the
route disabled with a typed diagnostic.
{% /consequence %}

{% consequence kind="neutral" %}
Token lifecycle remains in 1Password; dotfiles owns only retrieval and host-local
encryption.
{% /consequence %}


{% transition from="accepted" to="superseded" date="2026-08-15" %}
systemd-creds may be a future holder, but does not replace the required protected bootstrap token today.
{% /transition %}
