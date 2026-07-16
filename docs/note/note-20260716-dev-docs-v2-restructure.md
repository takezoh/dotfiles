---
id: note-20260716-dev-docs-v2-restructure
kind: note
title: dev-docs v2 documentation restructure
status: published
created: '2026-07-16'
topic: documentation-migration
summary: dotfiles の永続設計と判断履歴を dev-docs v2 へ整理し、module README は利用手順として維持した。
tags:
- dev-docs
- migration
owners: []
relations: []
source_paths: []
updated: '2026-07-16'
---

## Summary

root に v2 scaffold を導入し、environment bootstrap、shell runtime、developer tooling modules を active design として定義した。

## Notes

- root/module README はインストール、キー割当、具体的 command の利用者向け正本として残した。
- `external/` の submodule 文書は upstream 所有のため移行対象外とした。
- `.mcp.json` と `modules/shell/zsh/.zprofile` の既存変更には触れていない。
