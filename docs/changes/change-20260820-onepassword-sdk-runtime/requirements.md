---
change: change-20260820-onepassword-sdk-runtime
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Content

- R1: Given a valid owner-only token file, when credproxyd resolves either fixed
  route, then it uses the in-process 1Password SDK and injects the configured header.
- R2: Runtime production files must contain no service-account token environment
  export, WSLENV propagation, resolver command, or daemon `op` wrapper installation.
- R3: Initial setup and explicit refresh continue to atomically provision the
  token file with directories `0700` and file `0600`.
- R4: Missing or invalid token authority disables the route with
  `credential_source_unavailable`; no interactive fallback is attempted by daemon.
