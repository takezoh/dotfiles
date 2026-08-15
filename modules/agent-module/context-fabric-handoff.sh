#!/usr/bin/env bash
# Context Fabric runtime ownerへcredproxyの公開socket契約だけを渡す。
# credential materialやprovider tokenはこの境界を通さない。
set -euo pipefail
. "$MODULES_DIR/credproxy/socket-path.sh"
export CREDPROXY_BROKER_SOCKET="$(broker_socket_path)"
export CONTEXT_FABRIC_LEGACY_OWNER_STATE=absent
