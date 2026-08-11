# credproxy (module)

Per-terminal credential broker for sandboxed LLM agents. Builds and installs
[`credproxy`/`credproxyd`](https://github.com/takezoh/credproxy) (sibling repo),
a native headless `op`, and the config/hooks/wrappers that let a sandboxed agent
use secrets without ever holding them.

## What the three phases do

- **install**: build `credproxy` + `credproxyd` → `~/.local/bin`; install native
  Linux `op` → `/usr/local/bin/op`; copy `config.toml` / `hooks/op-resolve.py` /
  `wrappers/ctx-sync` into `~/.config/credproxyd/` (config is never overwritten).
- **setup**: install the systemd **user** unit; enable the daemon **only if** the
  service-account token exists. macOS → launchd (see below).
- **update**: rebuild the binaries and restart the daemon if running.

Everything is **inert until a 1Password service-account token is provisioned** —
the same skip pattern the grok-x-search venv uses.

## Design

The broker is the host-side half of the credential design (proposal v2). Assets:

| Asset | Role |
|---|---|
| `assets/config.toml` | Unix-socket-only daemon; one Tier-2 `ctx-sync` route |
| `assets/hooks/op-resolve.py` | route → fixed 1Password ref; `op read` with the token passed only to the `op` subprocess; typed `reason:` on failure |
| `assets/wrappers/ctx-sync` | fixed wrapper: `credproxy exec --route ctx-sync -- ctx …` |
| `assets/credproxyd.service` | hardened systemd user unit (`RuntimeDirectory` 0700, `ProtectHome=read-only`) |

Copies, never symlinks: the source lives in a sandbox-writable repo, so the
runtime assets must sit outside the agent's reach (same rationale as
context-fabric's copied `ctx`).

## go-live (blocked on human / session restart)

The module lays down everything buildable now. The hook resolves each ref from
a service-account live `op read` when a token file exists, and falls back to a
pre-resolved store file otherwise (`assets/hooks/op-resolve.py`).

### Path A — service account (primary; non-interactive rotation)

The daemon re-reads the current secret each TTL window, so rotation needs no
human step. 1Password **service accounts cannot read Personal/Private vaults**,
so the secret must live in a regular vault the account is scoped to — the
`local-dev` vault here — and vault access is fixed at service-account creation.

1. **Create the service account, token straight to file** (with your interactive
   `op`; `--raw` prints only the token so it never hits your terminal or me):
   ```sh
   mkdir -p ~/.secrets/op && chmod 700 ~/.secrets/op
   umask 077
   op service-account create credproxyd --expires-in 90d \
     --vault "local-dev:read_items" --raw \
     > ~/.secrets/op/service-account.token
   ```
   (If an earlier account is in the way: `op service-account delete <name>`.)
2. **Install native headless `op`** — the daemon runs `op` non-interactively,
   which the WSL `op.exe` shim cannot do. This needs root:
   ```sh
   bash modules/credproxy/install.sh   # in an interactive shell so sudo can prompt
   ```
3. **Enable the daemon** — `setup.sh` starts it once the token exists:
   ```sh
   bash modules/credproxy/setup.sh
   ```

The routes reference `op://local-dev/AI-API-Key/xAI/general` and
`op://local-dev/Context Fabric/PostgreSQL/url` (`ROUTE_ENV` in the hook).

### Path B — pre-resolved store (fallback; terminals without a token)

For a terminal where you cannot run a service account, resolve each ref once
with interactive `op` and write a 0600 store the broker reads instead — no token
and no native `op` needed:

```sh
mkdir -p ~/.secrets/credproxyd && chmod 700 ~/.secrets/credproxyd
umask 077
jq -n \
  --arg xai "$(op read 'op://local-dev/AI-API-Key/xAI/general')" \
  '{"op://local-dev/AI-API-Key/xAI/general": $xai}' \
  > ~/.secrets/credproxyd/resolved.json
```

Add one `--arg`/key line per ref. Rotation = re-run.

### Open the socket to the sandbox

The agent host's sandbox must allow the broker socket. For Claude Code this
module's agent-module counterpart already sets `sandbox.network.allowUnixSockets`
to `$XDG_RUNTIME_DIR/credproxyd/broker.sock` (per-path; never `allowAllUnixSockets`
— on WSL2 it also opens the Windows-interop socket) and `denyWrite` on
`~/.config/credproxyd`. **A session restart loads it; then verify a sandboxed
`credproxy exec --route ctx-sync -- true` reaches the socket** (per-path
reachability is the one end-to-end step still unverified).

### grok-x-search cutover

Once the `grok-x-search` route resolves, delete the plaintext
`~/.secrets/env/skills-grok-x-search-scripts` and the skill's `scripts/.env`.
`grok.py` falls back to the broker route when no plaintext key is present
(xai_sdk is gRPC, so Tier-1 header injection does not apply — the key is a
Tier-2 env). The `mise exec … grok.py` command is unchanged.

Until a store or token exists, the wrappers / grok.py report the broker as
unconfigured (or fall back to the existing plaintext env) rather than failing
silently.

## Verify a running broker

```sh
systemctl --user status credproxyd
curl --unix-socket "$XDG_RUNTIME_DIR/credproxyd/broker.sock" \
  -H "Authorization: Bearer $(cat ~/.config/credproxyd/token)" \
  http://broker/ctx-sync/        # → {"env":{"CTX_DATABASE_URL":"…"}}
```
