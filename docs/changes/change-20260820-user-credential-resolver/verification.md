---
change: change-20260820-user-credential-resolver
role: verification
---

<!-- lifecycle is owned by change.md -->

# Verification

## Content

- Resolver: `go test ./...`, `go vet ./...`, and `go build -o /tmp/... .`.
- Dotfiles: full `modules/credproxy/tests` suite and shell syntax checks.
- Structural checks: credproxy tree is clean; resolver contains no token environment
  or process-exec path; config uses only `credential_command`.
