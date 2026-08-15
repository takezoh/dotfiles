---
change: change-20260815-wsl-1password-authority
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

1. Add a WSL resolver authority that invokes one install-rendered Windows `op.exe` path for the fixed service-account item.
2. Sanitize the Windows child environment and provide the stable WSL interop socket when the user manager lacks `WSL_INTEROP`.
3. Add a WSL user unit without systemd credential directives.
4. Render and validate the expected 1Password WinGet executable during dotfiles install.
5. Probe the WSL authority before enabling credproxyd; keep native Linux provisioning separate.
6. Replace the platform-wide systemd decision with an explicit WSL/native-Linux/macOS authority decision.
