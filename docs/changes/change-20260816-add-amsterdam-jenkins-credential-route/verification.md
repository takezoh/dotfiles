---
change: change-20260816-add-amsterdam-jenkins-credential-route
role: verification
---

<!-- lifecycle is owned by change.md -->

# Verification

## Content

- `python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'` passes using fake values only.
- Resolver unit tests assert the Jenkins route produces the Authorization header from the fixed reference and rejects unknown routes.
- Source checks assert no consumer executable/argv policy or Jenkins TOKEN value is persisted.
- `docs lint` and `dev-evidence out-of-scope-changes.v2` pass.
- No live 1Password read or Jenkins request is required for repository verification.

## Results

- credproxy module unittest discovery: 43 passed.
- Concrete credential reference search: one match, only in `assets/hooks/op-resolve.py`.
- `git diff --check`: pass.
