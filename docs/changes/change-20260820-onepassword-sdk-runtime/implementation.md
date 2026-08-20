---
change: change-20260820-onepassword-sdk-runtime
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Content

- Render `[route.onepassword]` with fixed refs and the protected token path.
- Remove `credential_command`, `op-resolve.py`, trusted runtime `op` copy, and
  systemd PATH/credential-environment drop-ins.
- Keep `provision-service-account-token.sh` as the sole interactive boundary.
- Install a credproxyd build whose provider uses the official 1Password Go SDK.
