---
id: change-20260812-context-tier1-wiring
kind: change
title: Replace credproxy closed operations with Context Fabric Tier 1 wiring
status: done
created: '2026-08-12'
profile: sdd@1
intent: Replace closed command routing with protocol injection and remove cross-repository
  source pins.
outcomes:
- credproxy config contains only the Context Fabric HTTP injection route.
- closed-operation wrappers and manifests are absent.
- setup gates on service health without repository revisions or hook hashes.
scope:
- modules/credproxy
- dotfiles credential wiring design
non_goals:
- Context Fabric sync implementation
- credproxy proxy implementation
change_classes:
- responsibility
- boundary
- implementation_only
governance:
  gate: auto
  reasons: []
members:
- role: requirements
  path: changes/change-20260812-context-tier1-wiring/requirements.md
  required: true
- role: implementation
  path: changes/change-20260812-context-tier1-wiring/implementation.md
  required: true
- role: verification
  path: changes/change-20260812-context-tier1-wiring/verification.md
  required: true
evidence_refs:
- type: command
  ref: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
- type: command
  ref: bash -n modules/credproxy/install.sh modules/credproxy/setup.sh modules/credproxy/update.sh
- type: command
  ref: git diff --check
promotion:
- action: none
  reason: Persistent responsibility and wiring rules are already recorded in the new
    design and ADR in this repository.
unresolved_decisions: []
tags: []
owners: []
relations: []
source_paths:
- modules/credproxy
summary: dotfiles を service packaging と credential injection route の配線だけに限定し、closed
  operation 資産を除去する。
updated: '2026-08-12'
closure:
  closed_at: '2026-08-12T10:45:31.703864+00:00'
  content_hash: sha256:5163b6cd825de56957c6eedf7fd25e4bc43b76d42f1582329bfe28419b6c1a9b
---

## Summary

Make dotfiles a wiring owner only.

## Closure Notes
