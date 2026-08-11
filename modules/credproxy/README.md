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
one of two sources (`assets/hooks/op-resolve.py`): a pre-resolved store file, or
a service-account live `op read`. Pick the store path unless you specifically
need non-interactive rotation.

### Path B — pre-resolved store (recommended; no service account)

1Password **service accounts cannot read Personal/Private vaults**, and the
Individual-plan service-account UI is limited. Avoid all of that: resolve each
ref once with the interactive `op` you already have (the WSL `op.exe` desktop
integration reads Personal fine) and write the values to a 0600 store the broker
reads.

1. **Populate the store** — a JSON map of the exact `op://…` ref → value:
   ```sh
   mkdir -p ~/.secrets/credproxyd && chmod 700 ~/.secrets/credproxyd
   umask 077
   jq -n \
     --arg xai "$(op read 'op://Personal/AI-API-Key/xAI/general')" \
     '{"op://Personal/AI-API-Key/xAI/general": $xai}' \
     > ~/.secrets/credproxyd/resolved.json
   ```
   Add a `--arg`/key line per ref you use (e.g. the `ctx-sync` DB URL). The refs
   must match `ROUTE_ENV` in the hook exactly. `~/.secrets` is sandbox
   read-denied, so the agent cannot read this file. Rotation = re-run this.
2. **Enable the daemon** — `setup.sh` starts it once a store OR a token exists:
   ```sh
   bash modules/credproxy/setup.sh
   ```
   (No token file and no native `op` needed on this path.)

### Path A — service account (optional; non-interactive rotation)

Only if you want the broker to re-read a rotating secret without a human step.
Requires the secret in a **non-Personal** vault the service account is scoped to,
created at service-account time (vault access cannot be edited afterward). Via
CLI with your interactive `op`:

```sh
op vault create agent-secrets                      # SAs can't use Personal
# put the item in agent-secrets (app: duplicate/move), then:
mkdir -p ~/.secrets/op && chmod 700 ~/.secrets/op
op service-account create local-dev --expires-in 90d \
  --vault "agent-secrets:read_items" --raw \
  > ~/.secrets/op/service-account.token       # --raw = token only, straight to file
chmod 600 ~/.secrets/op/service-account.token
```

Then set the hook's refs to `op://agent-secrets/…`, install native `op`
(`sudo`-capable `install.sh`), and `setup.sh`. Delete a stuck account with
`op service-account delete <name>`.

### Both paths — open the socket to the sandbox

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
