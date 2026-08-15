---
change: change-20260815-protected-service-account-token-boundary
role: requirements
---

<!-- lifecycle is owned by change.md -->

# Requirements

## Requirements

- R1: Given protected tokenが存在しない, when setupを実行する, then固定Personal itemを
  human-authenticated 1Password CLIで一度だけ読み、固定pathへ`0600`で配置する。
- R2: Given有効なprotected tokenが存在する, when通常setupを再実行する, then
  1Password CLIを呼ばず既存tokenを再利用する。
- R3: Given明示refreshの1Password readが失敗する, then既存tokenを変更しない。
- R4: symlink、owner不一致、invalid modeまたは空tokenをtyped conflict/unavailableとして
  拒否し、user-owned targetを変更しない。
- R5: token valueをstdout/stderr、argv、report、evidence、knowledge artifactへ出さない。
- R6: resolverは固定pathだけを読み、固定native op childのenvironmentだけへtokenを渡す。
- R7: `~/.secrets` credential pathをsandbox allowlistへ追加しない。
- R8: fresh hostのcredproxy source取得はreviewed commit自体のdepth-1 fetch後にrevisionを
  検証してからcheckout/buildし、不完全な既存pathを上書きしない。
