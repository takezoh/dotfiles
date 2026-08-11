#!/usr/bin/env python3
"""credproxyd route hook: resolve a fixed secret ref to an env map.

Contract (credproxyd ScriptProvider):
  stdin : {"action","route","request","context"}
  stdout: {"body_replace": {"env": {...}}, "expires_in_sec": N}

The route -> ref mapping lives here, not in the request. The agent-facing
request cannot choose which secret is resolved; it can only reach a route that
this table already maps. Secrets reach the JSON stdout only — never argv or logs.

Two resolution sources, tried in order per ref:

1. **Pre-resolved store** (default, no service account needed): a 0600 JSON
   file (~/.secrets/credproxyd/resolved.json) mapping the op:// ref string to
   its value. Populate it once with an interactive `op read` (works with the
   WSL `op.exe` desktop integration), e.g.:
       op read "op://Personal/AI-API-Key/xAI/general"
   Rotation = re-run and rewrite the file. This path needs neither a service
   account (which cannot read Personal/Private vaults) nor a native headless op.

2. **Service-account live read** (optional upgrade for non-interactive
   rotation): if a ref is absent from the store and a service-account token
   file exists, run native `op read` with OP_SERVICE_ACCOUNT_TOKEN passed only
   to that subprocess. Requires the secret to live in a non-Personal vault the
   service account is scoped to.
"""
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import NoReturn

# route name -> {env var name: secret ref}. Fixed, host-owned. Route names are
# baked into clients and never change; ref item/field names follow 1Password.
ROUTE_ENV = {
    "ctx-sync": {
        "CTX_DATABASE_URL": "op://local-dev/context-fabric-pg/url",
    },
    "grok-x-search": {
        "XAI_API_KEY": "op://local-dev/AI-API-Key/xAI/general",
    },
}

# Static-secret TTL. credproxyd caches the response for expires_in_sec-30s.
EXPIRES_IN_SEC = 3600

OP_BIN = os.environ.get("CREDPROXY_OP_BIN", "/usr/local/bin/op")
TOKEN_FILE = os.environ.get(
    "CREDPROXY_OP_TOKEN_FILE",
    str(Path.home() / ".secrets/op/service-account.token"),
)
STORE_FILE = os.environ.get(
    "CREDPROXY_RESOLVED_STORE",
    str(Path.home() / ".secrets/credproxyd/resolved.json"),
)


def fail(reason: str) -> NoReturn:
    # First stderr line `reason:<token>` is surfaced by credproxyd as a typed
    # 502 reason; everything else stays server-side.
    sys.stderr.write(f"reason:{reason}\n")
    sys.exit(1)


def load_store() -> dict:
    try:
        data = json.loads(Path(STORE_FILE).read_text(encoding="utf-8"))
    except FileNotFoundError:
        return {}
    except (OSError, ValueError):
        fail("store_unreadable")
    if not isinstance(data, dict):
        fail("store_unreadable")
    return data


def load_token() -> str:
    try:
        token = Path(TOKEN_FILE).read_text(encoding="utf-8").strip()
    except OSError:
        return ""
    return token


def op_read(ref: str, token: str) -> str:
    try:
        proc = subprocess.run(
            [OP_BIN, "read", "--no-newline", ref],
            capture_output=True,
            text=True,
            timeout=8,
            env={**os.environ, "OP_SERVICE_ACCOUNT_TOKEN": token},
        )
    except (FileNotFoundError, subprocess.TimeoutExpired):
        fail("op_unreachable")
    if proc.returncode != 0:
        stderr = (proc.stderr or "").lower()
        if "rate" in stderr and "limit" in stderr:
            fail("op_rate_limited")
        if "isn't a vault" in stderr or "not found" in stderr or "no item" in stderr:
            fail("vault_denied")
        fail("op_unreachable")
    return proc.stdout


def resolve(ref: str, store: dict, token: str) -> str:
    if ref in store and isinstance(store[ref], str) and store[ref]:
        return store[ref]
    if token:
        return op_read(ref, token)
    # Neither a stored value nor a token: the operator has not provisioned this
    # ref. Surface it as an unavailable credential rather than a silent empty.
    fail("secret_unprovisioned")


def main() -> None:
    try:
        req = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        fail("bad_request")
    route = req.get("route", "")
    mapping = ROUTE_ENV.get(route)
    if mapping is None:
        fail("unknown_route")
    store = load_store()
    token = load_token()
    env = {name: resolve(ref, store, token) for name, ref in mapping.items()}
    json.dump({"body_replace": {"env": env}, "expires_in_sec": EXPIRES_IN_SEC}, sys.stdout)


if __name__ == "__main__":
    main()
