# context-fabric-service (module)

Context Fabric の local service を installed copy として配置し、OS service lifecycle
を管理する。product-owned config、credential、principal、remote sync semanticsは
所有しない。

- `install`: sibling repositoryから一時fileへbuildし、成功時だけ
  `~/.local/lib/context-fabric/bin/context-service`をatomicに置換する。
- `setup`: installed public CLI `~/.local/bin/ctx` と client config snapshot
  `~/.local/lib/context-fabric/client/.ctx/config.json` を使い、明示absolute pathsで
  `ctx service init`を呼ぶ。生成されたservice configをopaque inputとして消費し、
  systemd/launchdを設定して`GET /v1/healthz`を確認する。
- `update`: installed copyを更新し、既にactiveだったserviceだけを再起動する。

public CLI/client snapshotが無い場合、またはinitializerが失敗した場合はserviceを
停止してtyped nonzeroを返す。このmoduleはJSONを生成・補完せず、service principalや
bearerも扱わない。tenant `personal` はこのdeployment profileの明示choiceである。
