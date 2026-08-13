---
change: change-20260813-context-runtime-boundary
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Implementation

Add `modules/context-fabric-service` with three-phase lifecycle. `install` builds an
atomic trusted copy, `setup` consumes the product-owned config and manages
systemd/launchd plus public health, and `update` restarts only a previously active
service.

During setup, consume `~/.local/bin/ctx` and
`~/.local/lib/context-fabric/client/.ctx/config.json`, then call `ctx service init` with explicit
absolute paths and the `personal` deployment tenant. Share the platform broker socket
resolver with credproxy. Do not render JSON in dotfiles. Add `~/.local/bin` to the
systemd/launchd PATH used by context-service.

Remove context-service source/build/assets/lifecycle from `modules/credproxy`. Keep
only broker packaging, authority resolution, injection route, and legacy state
reconciliation. Resolve the broker socket in one shell function with Linux/WSL and
macOS branches, and order the modules explicitly in host profiles.
