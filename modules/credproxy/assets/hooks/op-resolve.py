#!/usr/bin/env python3
"""credproxyd route hook: resolve a fixed 1Password ref to an env map.

Contract (credproxyd ScriptProvider):
  stdin : {"action","route","request","context"}
  stdout: {"body_replace": {"env": {...}}, "expires_in_sec": N}

The route -> ref mapping lives here, not in the request. The agent-facing
request cannot choose which secret is resolved; it can only reach a route that
this table already maps. Secrets are read from `op` stdout and written to the
JSON stdout only — never passed through argv, env, or logs.

Auth: the 1Password service-account token is read from a file (default
~/.secrets/op/service-account.token) and passed only to the `op` subprocess
env, never kept in this hook's or the daemon's long-lived environment. The
native Linux `op` binary is required — the WSL `op.exe` shim is interactive and
cannot run headless.
"""
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

# route name -> {env var name: 1Password ref}. Fixed, host-owned.
# vault は service account "local-dev" に read-only で scope した agent-secrets。
# grok の item は Personal/AI-API-Key を名前そのまま copy したもの (ref の
# item/field 名は 1Password 側の実名に追随する — route 名は client に焼き込み
# 済みのため変えない)。
ROUTE_ENV = {
    "ctx-sync": {
        "CTX_DATABASE_URL": "op://agent-secrets/context-fabric-pg/url",
    },
    "grok-x-search": {
        "XAI_API_KEY": "op://agent-secrets/AI-API-Key/xAI/general",
    },
}

# Static-secret TTL. credproxyd caches the response for expires_in_sec-30s, so
# `op` is called at most once per route per TTL window (rate-limit friendly).
EXPIRES_IN_SEC = 3600

OP_BIN = os.environ.get("CREDPROXY_OP_BIN", "/usr/local/bin/op")
TOKEN_FILE = os.environ.get(
    "CREDPROXY_OP_TOKEN_FILE",
    str(Path.home() / ".secrets/op/service-account.token"),
)


def fail(reason: str) -> NoReturn:
    # First stderr line `reason:<token>` is surfaced by credproxyd as a typed
    # 502 reason; everything else stays server-side.
    sys.stderr.write(f"reason:{reason}\n")
    sys.exit(1)


def load_token() -> str:
    try:
        token = Path(TOKEN_FILE).read_text(encoding="utf-8").strip()
    except OSError:
        fail("op_token_invalid")
    if not token:
        fail("op_token_invalid")
    return token


def resolve(ref: str, token: str) -> str:
    try:
        proc = subprocess.run(
            [OP_BIN, "read", "--no-newline", ref],
            capture_output=True,
            text=True,
            timeout=8,
            env={**os.environ, "OP_SERVICE_ACCOUNT_TOKEN": token},
        )
    except FileNotFoundError:
        fail("op_unreachable")
    except subprocess.TimeoutExpired:
        fail("op_unreachable")
    if proc.returncode != 0:
        stderr = (proc.stderr or "").lower()
        if "rate" in stderr and "limit" in stderr:
            fail("op_rate_limited")
        if "isn't a vault" in stderr or "not found" in stderr or "no item" in stderr:
            fail("vault_denied")
        fail("op_unreachable")
    return proc.stdout


def main() -> None:
    try:
        req = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        fail("bad_request")
    route = req.get("route", "")
    mapping = ROUTE_ENV.get(route)
    if mapping is None:
        fail("unknown_route")
    token = load_token()
    env = {name: resolve(ref, token) for name, ref in mapping.items()}
    json.dump({"body_replace": {"env": env}, "expires_in_sec": EXPIRES_IN_SEC}, sys.stdout)


if __name__ == "__main__":
    main()
