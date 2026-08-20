---
id: adr-20260820-user-owned-credential-resolvers
kind: adr
title: Keep credential backends in user-owned resolvers
status: accepted
created: '2026-08-20'
decision_makers:
- takezoh
confirmation: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
consequences:
  positive:
  - Users can select a credential manager without changing credproxy.
  negative:
  - Each resolver owner must package and test its backend-specific dependencies.
  neutral:
  - credproxyd continues spawning a bounded credential command on cache miss or refresh.
tags:
- credproxy
- credential
- boundary
owners: []
relations:
- {type: supersedes, target: adr-20260820-in-process-onepassword-sdk}
source_paths:
- modules/credproxy
summary: credproxy consumes the generic credential-command JSON contract; users select
  and implement their credential backend outside the broker.
updated: '2026-08-20'
---

## Context

credproxy already exposes a bounded `credential_command` JSON contract. Adding a
1Password provider to credproxy would make the broker own one user's credential
manager and require core changes for every alternative backend.

## Decision

credproxy remains provider-neutral. The configured command owns credential-manager
selection, protected local authority access, SDK/CLI/API choice, fixed secret
references, and conversion to the generic injection JSON response.

The dotfiles-owned 1Password resolver reads the fixed protected token file and
passes the token directly to the official SDK. It does not place the token in an
environment or argv and does not invoke `op` or `op.exe`. Initial provisioning and
explicit refresh remain a separate setup-time interactive operation.

Users may replace `credential_command` with any resolver that implements the same
request/response and typed-failure contract; no credproxy modification is required.

{% consequence kind="positive" %}
Credential backend choice stays with the user integration owner instead of the broker.
{% /consequence %}

{% consequence kind="negative" %}
Each resolver owner must package and test backend-specific dependencies.
{% /consequence %}

{% consequence kind="neutral" %}
credproxyd still launches a bounded resolver process on cache miss or explicit refresh.
{% /consequence %}


{% transition from="proposed" to="accepted" date="2026-08-20" %}
User explicitly assigned 1Password access and credential-manager choice to the user resolver on 2026-08-20.
{% /transition %}
