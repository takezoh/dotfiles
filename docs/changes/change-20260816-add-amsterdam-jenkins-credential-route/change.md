---
id: change-20260816-add-amsterdam-jenkins-credential-route
kind: change
title: Add Amsterdam Jenkins credential route
status: done
created: '2026-08-16'
profile: sdd@1
intent: Amsterdam Jenkins Remote MCPのBearer credentialを1Password正本から取得し、credproxydの固定HTTP
  routeだけへ注入する。
outcomes:
- thirdverse-amsterdam-jenkins routeがJenkins Remote MCP endpointへBearer headerを注入する。
- TOKENは親環境、設定、argv、stdout、reportへ出ない。
scope:
- modules/credproxy/assets/config.toml
- modules/credproxy/assets/hooks/op-resolve.py
- modules/credproxy/README.md
- modules/credproxy/tests/test_secret_safe_paths.py
- modules/credproxy/tests/test_credential_inventory.py
- modules/credproxy/tests/probe_credential_authority.py
non_goals:
- Jenkins operationやtool schemaをdotfilesで所有しない。
- generic env delivery、consumer executable admission、直接secret解決surfaceを追加しない。
change_classes:
- behavior
- boundary
- responsibility
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260816-add-amsterdam-jenkins-credential-route/requirements.md
  required: true
- role: implementation
  path: changes/change-20260816-add-amsterdam-jenkins-credential-route/implementation.md
  required: true
- role: verification
  path: changes/change-20260816-add-amsterdam-jenkins-credential-route/verification.md
  required: true
promotion:
- action: none
  reason: active credential wiring design already owns protocol injection; this change
    adds one instance without changing the responsibility boundary.
unresolved_decisions: []
tags:
- credproxy
- jenkins
owners:
- repository owner
relations: []
source_paths:
- modules/credproxy/assets/config.toml
- modules/credproxy/assets/hooks/op-resolve.py
- modules/credproxy/README.md
- modules/credproxy/tests/test_secret_safe_paths.py
- modules/credproxy/tests/test_credential_inventory.py
- modules/credproxy/tests/probe_credential_authority.py
evidence_refs:
- type: test
  ref: python3 -m unittest discover -s modules/credproxy/tests -p test_*.py (43 passed)
- type: command
  ref: concrete credential reference search (trusted resolver source only)
summary: Add a fixed Jenkins HTTP injection route whose bearer is resolved only inside
  credproxyd's trusted provider hook.
updated: '2026-08-16'
closure:
  closed_at: '2026-08-16T01:43:43.577556+00:00'
  content_hash: sha256:cde253449931158b3e38521130400151cb9fbd4c1e7fbf275fbf1ac7a32e7681
---

## Summary

1Passwordの固定Amsterdam Jenkins token referenceをroute mappingだけから解決し、
credproxydがJenkins Remote MCPへのoutbound Authorization headerへ注入する。

## Closure Notes

Repository tests use fake credential values and do not expose the live token. The managed
credproxy configuration was installed, the daemon was restarted, and the Jenkins route was
then observed through the credential-isolated gateway flow without returning credential material.
