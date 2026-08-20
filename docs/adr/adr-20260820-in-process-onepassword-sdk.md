---
id: adr-20260820-in-process-onepassword-sdk
kind: adr
title: Keep the service-account token inside the broker process
status: superseded
created: '2026-08-20'
decision_makers:
- takezoh
confirmation: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
consequences:
  positive:
  - Context Fabric sync no longer launches 1Password CLI or requires human approval.
  negative:
  - credproxyd gains the official 1Password Go SDK and its transitive dependencies.
  neutral:
  - The protected plaintext bootstrap token file and setup-time provisioning remain.
tags:
- credproxy
- credential
- 1password
owners: []
relations:
- {type: supersedes, target: adr-20260815-protected-service-account-token-boundary}
- {type: supersedes, target: adr-20260819-use-the-path-resolved-windows-1password-}
source_paths:
- modules/credproxy
summary: Provision the token to the protected file, then pass it directly to the 1Password
  SDK without environment or helper-process delivery.
updated: '2026-08-20'
---

## Context

旧 runtime resolver は protected file の token を読み、子 `op` の
`OP_SERVICE_ACCOUNT_TOKEN` に設定していた。WSL ではそのために Windows `op.exe` と
PATH drop-in が daemon 起動条件になり、GUI と user approval を誘発し得た。ユーザーは
token を環境変数へ載せず、dotfiles setup が作る protected file を使うよう明示した。

## Decision

初回 setup または明示 refresh は固定 1Password item から
`~/.secrets/op/service-account.token` を atomic に provision する。runtime の credproxyd は
その固定 file を検証して読み、token を公式 1Password Go SDK の client constructor へ
プロセス内で直接渡す。token を environment、argv、log、evidence、knowledge artifact、
sandbox allowlist、helper process に渡さない。

runtime から resolver hook、`op`/`op.exe` child、WSL PATH drop-in、credential environment
drop-in を削除する。missing/invalid authority は `credential_source_unavailable` とし、daemon
から interactive fallback を行わない。

{% consequence kind="positive" %}
Context Fabric sync は 1Password CLI を起動せず、人間の password 入力や承認を要求しない。
{% /consequence %}

{% consequence kind="negative" %}
credproxyd は公式 1Password Go SDK とその transitive dependencies を持つ。
{% /consequence %}

{% consequence kind="neutral" %}
protected plaintext bootstrap token file と setup-time provisioning は維持する。
{% /consequence %}

Runtime boundary test は token environment、helper command、daemon op wrapper が無いことを検査する。


{% transition from="proposed" to="accepted" date="2026-08-20" %}
User explicitly required the protected setup token file and prohibited service-account token environment delivery on 2026-08-20.
{% /transition %}


{% transition from="accepted" to="superseded" date="2026-08-20" %}
Superseded by the user-owned resolver decision; credproxy remains provider-neutral.
{% /transition %}
