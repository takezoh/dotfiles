---
id: adr-20260815-protected-service-account-token-boundary
kind: adr
title: Keep the service-account bootstrap token in the protected local secret boundary
status: superseded
created: '2026-08-15'
decision_makers:
- takezoh
confirmation: python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
consequences:
  positive:
  - Human authentication is required only for initial provisioning or explicit refresh.
  negative:
  - The host keeps one plaintext bootstrap token under the protected ~/.secrets boundary.
  neutral:
  - 1Password remains canonical; a future systemd-creds integration changes only the
    local holder.
tags:
- credproxy
- credential
- 1password
owners: []
relations:
- {type: supersedes, target: adr-20260815-provision-systemd-credential-from-1password}
- {type: supersedes, target: adr-20260815-wsl-windows-1password-authority}
source_paths:
- modules/credproxy
summary: Keep 1Password canonical while provisioning its service-account bootstrap
  token once into the protected ~/.secrets boundary.
updated: '2026-08-20'
---

## Context

1Password Personal vaultへの人間の認証を毎回要求すると、service accountを使う目的を
満たせない。一方、service-account token自体は1Passwordに保存済みであり、dotfilesは
そのtokenを発行・rotateする責務を持たない。旧実装はこのbootstrap tokenを
`~/.secrets/op/service-account.token`へ一度だけ取得していた。

## Decision

1Passwordを正本とする。dotfilesは固定Personal itemからservice-account tokenを初回だけ
人間認証済みCLIで取得し、`~/.secrets/op/service-account.token`へatomicに配置する。
`~/.secrets`と`~/.secrets/op`はowner-only `0700`、tokenはowner-only `0600`とし、
symlink・owner不一致・mode不一致を拒否する。通常setupは有効な既存tokenを再利用し、
明示的な`--refresh`だけが1Passwordを再度読む。

resolverは固定pathだけを読み、tokenを固定native `op` childの
`OP_SERVICE_ACCOUNT_TOKEN`にだけ渡す。親environment、request指定path、log、evidence、
knowledge artifact、sandbox allowlistには渡さない。

fresh hostでcredproxy sourceが無い場合、dotfilesは固定repositoryからreviewed commit
そのものをdepth-1 fetchし、`FETCH_HEAD`一致後だけcheckout/buildする。
これはcredential broker自身のinstall identityであり、Context Fabric consumerや
routeのsource revision admissionには使わない。不完全な既存pathは上書きしない。

将来`systemd-creds`を導入する場合、それはこのservice-account tokenのhost-local holderを
置き換えるだけであり、1Passwordを正本から外さない。

## Consequences

{% consequence kind="positive" %}
初回または明示refresh以外は人間の1Password password入力なしでservice accountを使える。
{% /consequence %}

{% consequence kind="negative" %}
hostはprotected `~/.secrets`境界内にplaintext bootstrap tokenを1つ保持する。
{% /consequence %}

{% consequence kind="neutral" %}
tokenの発行・rotationと正本管理は引き続き1Password側のoperator責務である。
{% /consequence %}


{% transition from="proposed" to="accepted" date="2026-08-15" %}
User confirmed 1Password canonical plus one-time protected ~/.secrets bootstrap token semantics.
{% /transition %}


{% transition from="accepted" to="superseded" date="2026-08-20" %}
Superseded by adr-20260820-in-process-onepassword-sdk: runtime token delivery now stays inside credproxyd and no longer uses a CLI child.
{% /transition %}
