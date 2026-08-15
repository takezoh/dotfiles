---
change: change-20260815-protected-service-account-token-boundary
role: implementation
---

<!-- lifecycle is owned by change.md -->

# Implementation

## Implementation

- `provision-service-account-token.sh`を追加し、fixed item read、protected directory検証、
  owner-only temp file、atomic rename、明示refreshを実装する。
- resolverを`~/.secrets/op/service-account.token`の固定readへ戻し、file identityを検証する。
- systemd unitはfixed token existenceをconditionとし、homeをread-onlyに保つ。
- setupはsystemd-credsを要求せず、provisionerのtyped resultでroute lifecycleを制御する。
- 誤ったsystemd encrypted credential試作とWSL-specific unitを削除する。
- credproxy source欠落時だけfixed repositoryからreviewed commitをdepth-1 fetchし、
  bootstrap revision一致後にatomic配置する。
