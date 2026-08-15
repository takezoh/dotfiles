---
change: change-20260814-context-fabric-owner-cutover
role: requirements
---

# Requirements

- dotfiles MUST keep credproxy install/setup and secure credential authority ownership.
- Every agent-module phase adapter MUST export the exact `broker_socket_path` result as `CREDPROXY_BROKER_SOCKET` without credential data.
- Cutover profiles MUST invoke `agent-module` then `credproxy` and MUST NOT invoke `context-fabric-service`.
- The adapter MUST declare legacy runtime ownership absent after cutover.
- The legacy module source MUST remain available for explicit rollback until installed-host convergence is accepted.
- Missing operator credential MUST keep credproxyd disabled and MUST NOT trigger plaintext or parent-environment fallback.
