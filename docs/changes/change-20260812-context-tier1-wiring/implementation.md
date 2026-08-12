---
change: change-20260812-context-tier1-wiring
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Implementation

Remove the ctx wrapper/manifest and revision admission. Render a normal credproxyd
HTTP route whose fixed provider helper returns only an Authorization header. Replace
consumer identity checks with context-service health and repository conformance.
