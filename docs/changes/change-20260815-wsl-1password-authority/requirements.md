---
change: change-20260815-wsl-1password-authority
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

- FR-1: WSL MUST use the installed Windows 1Password CLI and one fixed Personal item as the service-account-token authority.
- FR-2: WSL MUST NOT require `systemd-creds`, a systemd encrypted credential, or an OS upgrade.
- FR-3: The token MUST exist only in resolver memory and the fixed native `op` child environment; it MUST NOT be persisted or logged.
- FR-4: The Windows CLI path MUST be rendered at install time from the expected 1Password WinGet package and MUST NOT be selected from a request.
- FR-5: Missing, locked, timed-out, or failing Windows 1Password authority MUST fail closed as `credential_source_unavailable`.
- FR-6: Native Linux systemd credentials and macOS Keychain behavior MUST remain platform-explicit and unchanged.

## Acceptance

- Given WSL and fake Windows/native op runners, the fixed item token reaches only the native child and no canary appears in output or persistent paths.
- Given the WSL unit, it contains neither `LoadCredential*` nor an encrypted-credential path condition.
- Given Ubuntu 22.04/systemd 249, setup selects the WSL authority branch before native-Linux provisioning.
