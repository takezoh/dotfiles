---
change: change-20260815-protected-service-account-token-boundary
role: verification
---

<!-- lifecycle is owned by change.md -->

# Verification

## Verification

- `python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'`
- `python3 modules/credproxy/tests/probe_credential_authority.py --self-test`
- `bash -n modules/credproxy/provision-service-account-token.sh modules/credproxy/setup.sh`
- `dev-docs lint --conformance`
- `git diff --check`
- 実host setup後、credential内容を読まずowner/mode/nonemptyだけを確認する。
- 実hostでcredproxydとContext Fabric remote sync経路を確認する。

## Host observation (2026-08-15)

- module install/setupは成功し、`~/.secrets`と`~/.secrets/op`はowner mode `0700`、
  tokenはowner mode `0600`のnonempty regular fileとして確認した（内容は未読・未出力）。
- 通常setupは`protected service-account token already present`で再利用し、credproxydは
  active/enabled。
- tokenを使ったnative `op whoami`はoutputを破棄した状態でexit 0。
- `ctx sync`はfixed Context Fabric item readで`op_unreachable`となり502。exact itemへの
  direct diagnosticは追加authorizationが無いため実施していない。remote sync gateは未達。
- 許可後の診断で1Password itemにbearer fieldが無いことと、credproxyがmatched prefixを
  stripするためbase-only upstreamが`/`へforwardされ404になることを確認した。
- user許可によりContext Fabric principalをrotateし、新bearerをprocess memoryから
  1Password item templateのstdinへ直接保存した。fixed referenceとの一致を値非表示で確認。
- agent-module owner scriptでContext Fabric runtime generationを再install/setupした。
- credproxy coreのexact route redirect / trailing-slash bugを回帰test付きで修正後、
  `go test ./...`はpass。
- `ctx sync`は`sync ok via Context Fabric service`、続く`ctx doctor`は全項目okで、
  remote sourceは2026-08-15T03:52:08Z取得の39 entitiesと確認した。
