---
id: adr-20260814-delegate-context-fabric-runtime-owner
kind: adr
title: Delegate Context Fabric runtime lifecycle to agent-module
status: accepted
created: '2026-08-14'
decision_makers:
- takezoh
consequences:
  positive:
  - Context Fabric runtime generationとservice lifecycleが一つのownerへ収束する。
  negative:
  - agent-module-first rolloutと明示rollback順序が必要になる。
  neutral:
  - dotfilesはprofile entrypointとcredproxy authorityを維持する。
tags:
- context-fabric
- ownership
owners: []
relations:
- {type: references, target: adr-20260716-agent-module-boundary}
- {type: originatedFrom, target: change-20260814-context-fabric-owner-cutover}
source_paths:
- modules/agent-module
- profiles/host-wsl.sh
- profiles/host-darwin.sh
- profiles/host-ubuntu-server.sh
summary: Dotfiles delegates Context Fabric runtime lifecycle and retains credproxy
  secure authority plus an explicit broker handoff.
updated: '2026-08-15'
---

## Context

旧構成はdotfilesの専用moduleがContext Fabric service lifecycleを持ったが、user-authoritative boundaryはruntime install/setupを`agent-module/modules/plugins`へ、credproxyをdotfilesへ置く。

## Decision

dotfilesはsupported profileから`context-fabric-service`を退役させ、thin agent-module adapterからinvocation-scoped `CREDPROXY_BROKER_SOCKET` とlegacy owner absent evidenceだけを渡す。credential、principal、provider tokenは渡さない。legacy module sourceはrollbackが検証されるまで保持する。

## Consequences

- Positive: runtime lifecycleのdual writerを排除できる。
- Negative: agent-module未更新のままdotfilesだけをcutoverできない。
- Neutral: credproxy authorityとoperator credential gateは変わらない。

## Alternatives

dual owner継続は競合と曖昧なrollbackを残すため採用しない。socket pathのagent-module側推測はplatform authorityを複製するため採用しない。


{% transition from="proposed" to="accepted" date="2026-08-15" %}
User confirmed agent-module owns Context Fabric runtime install/setup while dotfiles owns credproxy install/setup.
{% /transition %}
