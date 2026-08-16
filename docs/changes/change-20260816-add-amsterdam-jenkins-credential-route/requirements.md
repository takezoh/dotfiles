---
change: change-20260816-add-amsterdam-jenkins-credential-route
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Content

- R1: credproxyd shall expose an owner-only Unix-socket route named `thirdverse-amsterdam-jenkins` and proxy its exact route to `https://jenkins.ams.3vs.dev/mcp-server/mcp`.
- R2: the fixed resolver shall map only that route to the fixed Amsterdam Jenkins token reference and inject it as an `Authorization: Bearer` header.
- R3: the `op://` reference may exist only in the trusted resolver source; the resolved value shall appear only in the resolver response consumed by credproxyd.
- R4: inbound Authorization shall be stripped before the injected header is applied.
- R5: missing authority, denied vault access, or unavailable 1Password shall fail closed with the existing typed reasons.
- R6: dotfiles shall not name or execute Jenkins tools or consumer commands.
