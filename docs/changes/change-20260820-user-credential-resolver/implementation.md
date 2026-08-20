---
change: change-20260820-user-credential-resolver
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Content

- Restore the generic `credential_command` route configuration.
- Build/install a dotfiles-owned Go resolver using the official 1Password SDK.
- Keep setup-time provisioning as the only interactive CLI boundary.
- Remove the obsolete Python resolver, runtime op wrapper, and WSL PATH/environment drop-ins.
- Remove all 1Password-specific modifications from the credproxy repository.
