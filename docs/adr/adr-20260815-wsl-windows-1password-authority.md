---
id: adr-20260815-wsl-windows-1password-authority
kind: adr
title: Use Windows 1Password as the WSL credential authority
status: rejected
created: '2026-08-15'
decision_makers:
- unknown
tags: []
owners: []
relations: []
source_paths: []
updated: '2026-08-15'
---

<!-- 本文セクション構成はproducer方法論 (例: design/knowledge/artifact-semantics.md) が規定する。
     dev-docs skill 自体はセクション構成を強制しない。Markdoc tag `{% context %}` `{% decision %}` `{% consequence kind="positive" %}` を任意で本文に bind できる。 -->

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


{% transition from="proposed" to="rejected" date="2026-08-15" %}
Superseded by the protected local service-account token boundary.
{% /transition %}
