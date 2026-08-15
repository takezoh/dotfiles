---
change: change-20260814-context-fabric-owner-cutover
role: implementation
---

# Implementation

1. Add `modules/agent-module/context-fabric-handoff.sh` as the only dotfiles→agent-module socket producer.
2. Source the handoff from install/setup/update adapters.
3. Remove `context-fabric-service` from WSL, Darwin, and Ubuntu Server profile arrays while retaining its source for rollback.
4. Preserve credproxy module order immediately after agent-module.
5. Add static regression tests for exact exports, secret exclusion, and sole profile owner.

Rollback restores the legacy profile entry before disabling the agent-module lifecycle, then verifies service health.
