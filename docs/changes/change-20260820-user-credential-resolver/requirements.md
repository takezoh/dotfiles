---
change: change-20260820-user-credential-resolver
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Content

- R1: credproxyd must remain provider-neutral and consume only the existing
  credential-command request/response contract.
- R2: The configured user resolver reads `~/.secrets/op/service-account.token`
  and passes it directly to its SDK without environment, argv, or CLI delivery.
- R3: Replacing `credential_command` with another conforming resolver must not
  require a credproxy code change.
- R4: Missing or invalid authority fails closed with a typed reason and never
  starts an interactive runtime fallback.
