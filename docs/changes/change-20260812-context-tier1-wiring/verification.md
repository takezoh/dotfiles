---
change: change-20260812-context-tier1-wiring
role: verification
---

<!-- lifecycle is owned by change.md -->

# Verification

## Gates

- `python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'`
- `bash -n modules/credproxy/install.sh modules/credproxy/setup.sh`
- dev-docs lint with conformance
- `git diff --check`
