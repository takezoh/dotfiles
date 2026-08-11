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

The module lays down everything buildable now. These steps need actions the
install cannot take on its own:

1. **1Password service account** — create one at my.1password.com (Developer
   Tools → Service Accounts), scoped read-only to the `agent-secrets` vault.
   Waiting on: human UI action; confirm Individual-plan availability there.
2. **Provision the token** — write it to `~/.secrets/op/service-account.token`
   (mode 0600). `~/.secrets` is sandbox read-denied, so the agent cannot read it.
   Re-run `setup.sh` to enable the daemon.
3. **Open the socket to the sandbox** — add the broker socket path to the agent
   host's sandbox settings (Claude Code: `sandbox.network.allowUnixSockets`
   with the per-path entry `$XDG_RUNTIME_DIR/credproxyd/broker.sock`; do NOT use
   `allowAllUnixSockets` — on WSL2 it also opens the Windows-interop socket).
   Add `~/.config/credproxyd/{config.toml,hooks,wrappers}` to `denyWrite` so the
   agent cannot rewrite the fixed routes. Waiting on: a session restart to load
   the setting, then verify a sandboxed `credproxy exec --route ctx-sync -- true`
   reaches the socket (per-path reachability is unverified end-to-end).
4. **grok-x-search cutover** — provision `op://agent-secrets/xai/api-key`, then
   delete the plaintext `~/.secrets/env/skills-grok-x-search-scripts` and the
   skill's `scripts/.env`. `grok.py` already falls back to the broker's
   `grok-x-search` route when no plaintext key is present (xai_sdk is gRPC, so
   Tier 1 header-injection does not apply — the key is served as a Tier-2 env).
   No skill-command change; the `mise exec … grok.py` invocation is unchanged.

Until step 2, `ctx doctor` / the wrappers / grok.py report the broker as
unconfigured (or fall back to the existing plaintext env) rather than failing
silently.

## Verify a running broker

```sh
systemctl --user status credproxyd
curl --unix-socket "$XDG_RUNTIME_DIR/credproxyd/broker.sock" \
  -H "Authorization: Bearer $(cat ~/.config/credproxyd/token)" \
  http://broker/ctx-sync/        # → {"env":{"CTX_DATABASE_URL":"…"}}
```
