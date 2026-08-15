---
id: change-20260815-wsl-1password-authority
kind: change
title: Use Windows 1Password authority on WSL
status: abandoned
created: '2026-08-15'
profile: sdd@1
intent: Ubuntu 22.04/systemd 249を維持したまま、WSLではWindows 1Password CLIを固定authorityとしてservice-account
  tokenを平文永続化せず利用する。
outcomes:
- WSL setupはsystemd-credsを要求しない。
- resolverは固定Windows op.exeで固定itemを読み、tokenをnative op childだけへ渡す。
- native Linuxのsystemd encrypted credential branchとmacOS Keychain branchを保持する。
scope:
- modules/credproxy/assets/hooks/op-resolve.py
- modules/credproxy/assets/systemd/user/credproxyd-wsl.service
- modules/credproxy/install.sh
- modules/credproxy/setup.sh
- modules/credproxy/tests
- modules/credproxy/README.md
- docs/design/design-credential-integration-wiring-boundary.md
- docs/adr/adr-20260815-wsl-windows-1password-authority.md
non_goals:
- WSL distributionまたはsystemdのupgrade
- service-account tokenのissue、rotate、delete
- agent-module、context-fabric、mcp-gatewayへのcredential処理追加
change_classes:
- capability
- boundary
- invariant
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260815-wsl-1password-authority/requirements.md
  required: true
- role: implementation
  path: changes/change-20260815-wsl-1password-authority/implementation.md
  required: true
- role: verification
  path: changes/change-20260815-wsl-1password-authority/verification.md
  required: true
promotion:
- target: design-credential-integration-wiring-boundary
  section: responsibilities
  action: upsert
  item:
    id: RESP-001
    statement: Retrieve the stored service-account token through the fixed host-compatible
      authority without plaintext persistence, and install injection routes and OS
      service definitions without owning product semantics.
unresolved_decisions: []
tags:
- credproxy
- wsl
- credential
owners: []
relations:
- {type: introduces, target: adr-20260815-wsl-windows-1password-authority}
- {type: modifies, target: design-credential-integration-wiring-boundary}
source_paths: []
updated: '2026-08-15'
---

## Summary

WSLはWindows 1Password CLIをauthorityとして固定itemを都度解決する。tokenは
resolver memoryとnative op child environmentにだけ存在し、fileやsystemd managerへ
永続化しない。native Linuxだけがsystemd encrypted credentialを使う。

{% transition from="draft" to="ready" date="2026-08-15" %}
Ubuntu 22.04を維持するhost前提とsecurity gateを確定
{% /transition %}

{% transition from="ready" to="active" date="2026-08-15" %}
RED test後に実装着手
{% /transition %}

## Closure Notes


{% transition from="active" to="abandoned" date="2026-08-15" %}
User clarified that the service-account bootstrap token is retrieved once into ~/.secrets; per-request Windows op.exe authority is the wrong contract.
{% /transition %}
