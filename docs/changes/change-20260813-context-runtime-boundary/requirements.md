---
change: change-20260813-context-runtime-boundary
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Requirements

- Context Fabric service install MUST build to a temporary file and replace the
  installed copy only after a successful build.
- Missing source, runtime, public CLI/client snapshot, service manager, or health MUST be
  surfaced as typed nonzero failure without creating product config.
- Setup MUST invoke the installed `ctx service init` with explicit absolute service,
  state, snapshot, principals, and broker-socket paths before starting the service.
- credproxy MUST NOT build, install, configure, or manage context-service.
- dotfiles MUST NOT generate service config fields, credentials, principals, or
  remote sync semantics.
- Host profiles MUST order `agent-module`, `context-fabric-service`, then `credproxy`.
- The broker socket path MUST be resolved once per platform and used by the rendered
  proxy config and matching OS runtime directory.
- Missing secure authority or upstream health MUST leave the proxy route disabled.
- The context-service environment MUST include the installed user binary directory so
  product-owned source helpers can resolve at runtime.
