---
id: change-20260815-op-systemd-credential-provision
kind: change
title: Provision credproxy systemd credential from 1Password
status: done
created: '2026-08-15'
profile: sdd@1
intent: 1Passwordに保存済みのservice-account tokenをdotfilesが取得し、平文を永続化せずcredproxyd用systemd
  user credentialへ変換する。
outcomes:
- setupはencrypted credential不在時にfixed 1Password itemから安全にprovisionする。
- refreshは既存ciphertextを成功後だけatomicに置換する。
- source unavailableまたはidentity conflictではdaemonを有効化しない。
scope:
- modules/credproxy/provision-systemd-credential.sh
- modules/credproxy/setup.sh
- modules/credproxy/README.md
- modules/credproxy/tests
- docs/design/design-credential-integration-wiring-boundary.md
- docs/adr/adr-20260815-provision-systemd-credential-from-1password.md
non_goals:
- 1Password service accountのissue、rotate、delete
- Context Fabric principalのissue、rotate、revoke
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
  path: changes/change-20260815-op-systemd-credential-provision/requirements.md
  required: true
- role: implementation
  path: changes/change-20260815-op-systemd-credential-provision/implementation.md
  required: true
- role: verification
  path: changes/change-20260815-op-systemd-credential-provision/verification.md
  required: true
evidence_refs:
- type: command
  ref: python3 -m unittest modules.credproxy.tests.test_systemd_credential_provision
    (8 tests OK)
- type: command
  ref: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py' (43
    tests OK)
- type: command
  ref: python3 -m unittest modules.editor-nvim.tests.test_minuet_credentialless (1
    test OK)
- type: command
  ref: bash -n modules/credproxy/provision-systemd-credential.sh modules/credproxy/setup.sh
- type: command
  ref: dev-docs lint --conformance
- type: command
  ref: git diff --check
promotion:
- target: design-credential-integration-wiring-boundary
  section: responsibilities
  action: upsert
  item:
    id: RESP-001
    statement: Retrieve the stored service-account token from the fixed 1Password
      item, convert it directly to an OS-private credential without plaintext persistence,
      and install injection routes and OS service definitions without owning product
      semantics.
unresolved_decisions: []
tags:
- credproxy
- credential
- systemd
owners: []
relations:
- {type: introduces, target: adr-20260815-provision-systemd-credential-from-1password}
- {type: modifies, target: design-credential-integration-wiring-boundary}
source_paths: []
summary: Retrieve the stored 1Password service-account token and atomically encrypt
  it for the credproxyd user service without plaintext persistence.
updated: '2026-08-15'
promotion_applied_at: '2026-08-14T17:37:58.482828+00:00'
closure:
  closed_at: '2026-08-14T17:38:22.661267+00:00'
  content_hash: sha256:40b7088f0c496846683dd5035032b2c6f27dd36b995856bff79816b6947d59b9
---

## Summary

`op read`のstdoutを`systemd-creds --user encrypt`のstdinへ直接接続する。既存の
plaintext token fileを復活させず、暗号化成功前にinstalled credentialを変更しない。

{% transition from="draft" to="ready" date="2026-08-15" %}
責務とsecurity gateを確定
{% /transition %}

{% transition from="ready" to="active" date="2026-08-15" %}
RED test後に実装着手
{% /transition %}

## Closure Notes


{% transition from="active" to="closing" date="2026-08-15" %}
Repository gates and independent security review passed; real-host execution remains unavailable on systemd 249 and did not read 1Password.
{% /transition %}
