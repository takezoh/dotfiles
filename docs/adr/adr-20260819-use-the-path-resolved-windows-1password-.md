---
id: adr-20260819-use-the-path-resolved-windows-1password-
kind: adr
title: Use the PATH-resolved Windows 1Password wrapper on WSL
status: superseded
created: '2026-08-19'
decision_makers:
- takezoh
tags: []
owners: []
relations:
- {type: references, target: adr-20260815-protected-service-account-token-boundary}
source_paths:
- modules/credproxy
summary: Use the existing PATH-level Windows op.exe wrapper for WSL while retaining
  protected local token injection.
confirmation: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
updated: '2026-08-20'
---

## Context

WSL の対話 shell では dotfiles の `scripts/wsl/op` が PATH 上の `op` を所有し、
Windows 1Password CLI (`op.exe`) へ委譲している。一方 systemd user manager の PATH
にはこの wrapper と Windows CLI の directory が含まれない。native Linux CLI を別途
導入すると、対話時と daemon 時で 1Password authority が分裂する。

## Decision

WSL では `op` をコマンド名で呼び、フルパスで CLI を実行しない。install は既存の
`scripts/wsl/op` を trusted runtime へ regular copy として配置する。setup は PATH 上の
公式 Windows `op.exe` を検証し、trusted wrapper directory と Windows CLI directory
だけを含む machine-local systemd drop-in を生成する。resolver は protected local token
を child の環境へだけ渡す。

非 WSL Linux は root-owned native `/usr/local/bin/op`、macOS は既存 Keychain authorityを
維持する。repository 内 wrapper を daemon が直接実行すること、親 PATH 全体を serviceへ
複製すること、request から executable/path を選ばせることは禁止する。

## Consequences

{% consequence kind="positive" %}
WSL の対話操作と daemon が同じ Windows 1Password CLI authority を利用する。
{% /consequence %}

{% consequence kind="negative" %}
Windows 1Password CLI の install directory が変わると setup の再実行が必要になる。
{% /consequence %}

{% consequence kind="neutral" %}
protected `~/.secrets/op/service-account.token` の holder と fixed route contract は変わらない。
{% /consequence %}


{% transition from="proposed" to="accepted" date="2026-08-19" %}
User confirmed WSL must use the PATH-level Windows op.exe wrapper and must not invoke the CLI by full path.
{% /transition %}


{% transition from="accepted" to="superseded" date="2026-08-20" %}
Superseded by adr-20260820-in-process-onepassword-sdk: runtime token delivery now stays inside credproxyd and no longer uses a CLI child.
{% /transition %}
