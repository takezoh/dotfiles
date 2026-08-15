---
change: change-20260815-op-systemd-credential-provision
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Changes

1. Add `modules/credproxy/provision-systemd-credential.sh` as the sole Linux conversion boundary.
2. Keep the 1Password reference fixed and send `op read --no-newline` output directly to `systemd-creds --user encrypt`.
3. Validate installed credential type, owner, and mode before reuse or refresh.
4. Stage ciphertext in the owner-only credential directory and rename it atomically.
5. Invoke provisioning from `setup.sh` before enabling credproxyd.
6. Preserve typed unavailable versus conflicting exit outcomes.

## Security Notes

The implementation never reads credential output back for validation. Tests use a
nonsecret canary and assert its absence from stdout, stderr, and persistent paths.
The encrypted output bytes are opaque to dotfiles.
