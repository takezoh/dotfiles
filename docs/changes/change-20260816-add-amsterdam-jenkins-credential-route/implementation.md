---
change: change-20260816-add-amsterdam-jenkins-credential-route
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Content

1. Add a fixed Jenkins route to the managed credproxyd config with exact upstream URL, shared resolver hook, inbound auth stripping, and 401 refresh.
2. Add the route/header/reference tuple to the trusted `op-resolve.py` mapping.
3. Extend secret-safe, route-inventory, and resolver tests without reading any real credential.
4. Document the route as protocol injection owned by dotfiles, with MCP operation semantics owned by mcp-gateway/Jenkins.
