---
change: change-20260815-op-systemd-credential-provision
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Functional Requirements

- FR-1: Dotfiles MUST read the service-account token from the fixed 1Password Personal item only when the encrypted credential is absent or an operator explicitly requests refresh.
- FR-2: Dotfiles MUST pipe the token directly into user-scoped `systemd-creds encrypt` without storing it in a shell variable, argv, plaintext file, log, or evidence.
- FR-3: Provisioning MUST atomically commit mode-0600 ciphertext under the credproxyd credential directory.
- FR-4: Existing valid ciphertext MUST be reused by normal setup.
- FR-5: Source, encryption, identity, ownership, or mode failure MUST keep credproxyd disabled and MUST preserve an existing valid credential.
- FR-6: Dotfiles MUST NOT issue or rotate the 1Password service account or a Context Fabric principal.

## Acceptance

- Given a fake fixed 1Password source and fake user-scoped systemd encryptor, provisioning produces only the expected ciphertext and emits no token canary.
- Given an existing valid credential, normal provisioning does not call 1Password.
- Given explicit refresh, replacement occurs only after successful encryption.
- Given a symlink or unsupported user encryption, provisioning fails closed without modifying user state.
