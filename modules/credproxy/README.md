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

Two secrets, two `op` binaries, cleanly separated:

- The **service-account token** is stored as a 1Password Personal item and
  resolved at **setup time** by the *interactive* `op` (op.exe reads Personal;
  the service account cannot). `setup.sh` writes it to
  `~/.secrets/op/service-account.token` (0600) — see `CREDPROXY_SA_TOKEN_REF`,
  default `op://Personal/4h3467uq736jjlju6xkeu6uvyq/credential`.
- The **actual secrets** (xAI key, DB URL) live in the `local-dev` vault and are
  read at **daemon time** by the *native headless* `op` using that token.

Steps:

1. **Store the SA token in Personal** — when you create the service account,
   save its token as the Personal item `CREDPROXY_SA_TOKEN_REF` points at:
   ```sh
   op service-account create credproxyd --expires-in 90d \
     --vault "local-dev:read_items" --raw     # copy the token into that item
   ```
   (Delete a stuck account with `op service-account delete <name>`.)
2. **Install native headless `op`** (daemon-side, needs root):
   ```sh
   bash modules/credproxy/install.sh   # interactive shell so sudo can prompt
   ```
3. **Provision + enable** — `setup.sh` runs `op signin` if `op` is not already
   authenticated (desktop-app integration satisfies `op whoami` on its own),
   resolves the token from Personal, writes the token file, and starts (or
   restarts, clearing cache) the daemon. Run it in an interactive terminal so
   the auth prompt can appear:
   ```sh
   bash modules/credproxy/setup.sh
   ```
   If `op signin` can't run (no account added, non-interactive), place the token
   by hand instead — `setup.sh` never overwrites an existing token file:
   ```sh
   mkdir -p ~/.secrets/op && chmod 700 ~/.secrets/op
   umask 077; cat > ~/.secrets/op/service-account.token   # paste token, Ctrl-D
   ```

Rotation: update the Personal item (or the vault secret), then `rm
~/.secrets/op/service-account.token` and re-run `setup.sh`. The routes reference
`op://local-dev/AI-API-Key/xAI/general` and
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

### How secrets reach a sandboxed consumer

A sandboxed process **cannot reach the broker socket** — that is what a sandbox
is, and it holds on every host (Linux blocks unix sockets with a seccomp filter
that cannot match by path, so `allowUnixSockets` is macOS-only; a host loopback
TCP port is no better, since the sandbox has its own network namespace and a TCP
port would lose the socket's 0600 + SO_PEERCRED protection).

So the supply path is the one channel every host shares — **the parent
environment**:

1. At login (outside the sandbox) the shell snippet runs `credproxy env`, which
   asks the broker for every env route and exports the results.
2. The agent host starts as a child of that shell and inherits them.
3. The sandboxed consumer reads the value from its own environment.

**Adding a key never touches the consumer side.** The snippet is fixed; only the
broker's `ROUTE_ENV` gains a line.

This means the key is readable by whatever runs in the sandbox — true on every
host, because the consumer must hold it. Narrow the blast radius at the
credential (per-route separation, read-only vault scope, rotation), not at the
host.

**Claude adds an optional layer.** `sandbox.credentials.envVars` masks the value
so sandboxed processes see only a sentinel, and the egress proxy substitutes the
real one for `injectHosts` requests (it needs `network.tlsTerminate`, and
`injectHosts` must be inside `allowedDomains`). It changes nothing structural —
same snippet, same route, same consumer — and it is honored only from user or
managed settings, never a repository's `.claude/settings.json`. It stops the key
from being *read*, not from being *used* against that host, so it is not a
substitute for narrowing the credential itself.

### grok-x-search cutover

`grok.py` now reads `XAI_API_KEY` from its environment only — the `.env` file and
the broker-socket fallback are both gone, because neither works from inside a
sandbox. Supply comes from the login-shell snippet above.

After the broker resolves the `grok-x-search` route, delete the plaintext
`~/.secrets/env/skills-grok-x-search-scripts` and the skill's `scripts/.env`.
Retire them only once a shell started after `setup.sh` shows the key present —
otherwise the skill has no source at all.

Until then `grok.py` exits 2 with `error: xai_key_unprovisioned` and prints the
host and platform, so an unsupplied key is visible rather than silent.

## Verify a running broker

```sh
systemctl --user status credproxyd
curl --unix-socket "$XDG_RUNTIME_DIR/credproxyd/broker.sock" \
  -H "Authorization: Bearer $(cat ~/.config/credproxyd/token)" \
  http://broker/ctx-sync/        # → {"env":{"CTX_DATABASE_URL":"…"}}
```
