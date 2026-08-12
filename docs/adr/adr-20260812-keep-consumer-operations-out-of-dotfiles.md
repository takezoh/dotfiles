---
id: adr-20260812-keep-consumer-operations-out-of-dotfiles
kind: adr
title: Keep consumer operations out of dotfiles credential wiring
status: accepted
created: '2026-08-12'
decision_makers:
- takezoh
confirmation: python3 -m unittest discover -s modules/credproxy/tests -p test_*.py
consequences:
  positive:
  - Product responsibilities remain in their owning repositories.
  negative:
  - Setup must wait for protocol-level service readiness instead of pinning source
    bytes.
  neutral:
  - OS authority and service lifecycle remain dotfiles responsibilities.
tags: []
owners: []
relations: []
source_paths:
- modules/credproxy
summary: dotfiles packages services and routes but does not define or execute consumer
  operations.
---

## Context

The previous setup duplicated Context Fabric commits, hook hashes, executable
identity, argv grammar, and a credproxy closed operation. This made dotfiles a second
owner of two products' semantics.

## Decision

dotfiles owns only secure authority, installed copies, service lifecycle, route
wiring, and reconciliation of files it previously managed. It validates live public
protocol readiness, not source repository identities.

Context Fabric sync is wired as an exact HTTP injection route. No closed operation,
consumer executable, argv policy, or repository revision is allowed.

## Consequences

{% consequence kind="positive" %}
Product upgrades no longer require copying their source commit into setup admission.
{% /consequence %}

{% consequence kind="negative" %}
Cutover waits until context-service is healthy and its service principal is ready.
{% /consequence %}

{% consequence kind="neutral" %}
The exact checksum of the old dotfiles-managed shell file remains a file-ownership
reconciliation fact, not a product revision pin.
{% /consequence %}

<!-- CONSEQUENCES: Nygard 対称ルール — positive / negative / neutral の 3 極を本文でも書き出す (skills/design/knowledge/artifact-semantics.md §18 / adr-20260709-adr-consequences-tripolar)。
     frontmatter の consequences{positive[], negative[], neutral[]} が SoT。spec-detail 導入以降 (created >= 2026-07-09) の新規 ADR は三極必須。

  {% consequence kind="positive" %} ... {% /consequence %}
  {% consequence kind="negative" %} ... {% /consequence %}
  {% consequence kind="neutral" %}  ... {% /consequence %}
-->

<!-- OPTIONAL: `confirmation` block (MADR 5.0 由来、spec-detail v1、skills/design/knowledge/artifact-semantics.md §18)。
     この decision が守られていることを機械的に確認する手段 (fitness function / grep / test) を書く。
     frontmatter `confirmation:` (string) が SoT。使うときはこのコメントを削除して次のブロックを埋める。

  {% confirmation %} ... {% /confirmation %}
-->
