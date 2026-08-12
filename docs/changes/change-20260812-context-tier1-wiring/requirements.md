---
change: change-20260812-context-tier1-wiring
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Requirements

- Production wiring MUST NOT contain closed operations, consumer commands, argv
  policy, external repository revisions, or hook hashes.
- credproxyd MUST inject the Context Fabric service bearer only for
  `/v1/sync/remote`.
- Setup MUST preserve unknown user state and MUST preserve the old managed profile
  until context-service is healthy.
- Persistent plaintext credential fallback MUST remain absent.
