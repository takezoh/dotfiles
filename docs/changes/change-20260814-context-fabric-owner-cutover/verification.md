---
change: change-20260814-context-fabric-owner-cutover
role: verification
---

# Verification

- `python3 -m unittest discover -s modules/agent-module/tests -p 'test_*.py'`
- `bash -n modules/agent-module/*.sh profiles/host-wsl.sh profiles/host-darwin.sh profiles/host-ubuntu-server.sh`
- Existing credproxy test suite remains green.
- Installed-host T2 must observe one Context Fabric runtime owner, healthy service, exact broker socket type, and credential-gated proxy state.
