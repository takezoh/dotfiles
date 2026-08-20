---
change: change-20260820-onepassword-sdk-runtime
role: verification
---

<!-- lifecycle is owned by change.md -->

# Verification

## Content

- `python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'`
- `bash -n modules/credproxy/install.sh modules/credproxy/setup.sh modules/credproxy/provision-service-account-token.sh`
- credproxy: `go vet ./...`, `go build ./...`, `go test ./...`
- Installed host: restart credproxyd and execute Context Fabric sync with no
  1Password UI and no service-account token environment variable.
