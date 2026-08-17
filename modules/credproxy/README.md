# credproxy (module)

Credential authority and protocol-injection wiring. Runtime assets are installed as
copies outside the workspace. 1Password remains the canonical source; dotfiles
provisions only the service-account bootstrap token into the protected local
`~/.secrets` boundary.

## Authority branches

- Linux / WSL: setup reads the service-account token once from one fixed
  1Password Personal item using the human-authenticated CLI, then atomically
  writes `~/.secrets/op/service-account.token` (directories `0700`, file `0600`).
  The resolver reads only that fixed path and passes the token only in the
  environment of fixed native `/usr/local/bin/op`.
- macOS: the resolver invokes fixed `/usr/bin/security` for service
  `com.takezoh.credproxy.op-service-account`, account `credproxyd`, then passes
  the result only to the fixed `op` child.
- Any other/missing/stale mechanism: `credential_source_unavailable`; setup
  disables the daemon/route. There is no parent-environment or request-selected
  credential fallback.

The service-account token remains owned by 1Password. Its protected local copy is
the bootstrap credential that avoids a human password prompt on every service-account
operation. Normal setup reuses a valid copy and does not call 1Password again.
Tests use only fake, nonsecret material. Do not place
credential values, prefixes, hashes, lengths, or canaries in reports.

After the token stored in 1Password is rotated, explicitly refresh the protected
copy and restart the service:

```sh
bash modules/credproxy/provision-service-account-token.sh --refresh
bash modules/credproxy/setup.sh
```

Refresh stages a new owner-only file and atomically replaces the old token only
after the 1Password read succeeds. A future `systemd-creds` integration may hold
this bootstrap token instead; it does not replace 1Password as the canonical source.
The credential path must not be added to sandbox allowlists, logs, evidence, or
knowledge artifacts.

## Consumer disposition

| Consumer | Outcome |
|---|---|
| Context Fabric remote sync | `POST /v1/sync/remote` is proxied to context-service; credproxy injects only the Context Fabric service bearer header. Context Fabric owns the operation. |
| Thirdverse Amsterdam Jenkins MCP | The owner-only Unix-socket route `thirdverse-amsterdam-jenkins` proxies the exact Remote MCP endpoint and injects its bearer header from the fixed 1Password reference. mcp-gateway and Jenkins own MCP operation semantics. |
| Minuet / Anthropic | provider disabled: current credproxyd cannot prove executable-bound caller admission plus exact `POST https://api.anthropic.com/v1/messages`; no adapter/key callback/env fallback |
| grok-x-search / XAI | legacy key route retired from revision-matched OAuth-only consumer proof; generic env delivery and ctx route remain |

The legacy login-shell export asset and its setup copy were removed after the
D2 evidence checkpoint and the revision-bound removal admission. `setup`
reconciles only the exact D2 managed installed profile (fixed path, owner,
regular-file provenance, and checksum). Unknown or user-modified content is
left in place and reported as `conflicting`; migration stops instead of
deleting user state.

There is no executable, argv, subcommand, binding revision, or Context Fabric source
revision in this module. The route is an HTTP injection route; context-service
authenticates and performs sync. Runtime identities are install-time copies under
`~/.local/lib/credproxy` and are not placed in the sandbox allowlist.

`context-service` の installed copy と OS lifecycle は sibling `agent-module` の
`modules/plugins` が所有する。credproxy setup は公開
`GET /v1/healthz` だけを upstream readiness として消費し、service config、service
principal、source、sync semantics を生成・解釈しない。

broker socket はこの module が platform ごとに一度だけ解決する。Linux/WSL は
`${XDG_RUNTIME_DIR:-/run/user/$uid}/credproxyd/broker.sock`、macOS は
`~/Library/Caches/credproxyd/runtime/credproxyd/broker.sock` で、rendered config と
service manager が同じ path を使う。Context Fabric 側の端末固有 config もこの
値を thin `modules/agent-module` handoff から agent-module 所有の public
`ctx service init`へ明示入力として渡す。dotfiles はその config schema を直接編集しない。

## Phases

- `install`: build the broker binaries; copy resolver,
  editor client, binding, service-manager assets, and proxy config.
  If the sibling credproxy source is absent, install depth-1 fetches the exact reviewed
  bootstrap commit into a no-checkout temporary repository, verifies `FETCH_HEAD`, then
  checks out/builds it. Branch HEAD movement does not affect bootstrap. An incomplete
  existing path is conflicting and is never replaced.
  Config has a managed provenance sidecar and exact source/installed revisions;
  unknown, locally modified, or source-new/installed-old state is conflicting.
- `setup`: provision or validate the fixed protected service-account token, then
  remove the exact known managed shell profile only after
  the separately managed context-service health, managed proxy wiring, and the
  selected secure authority are available; stop on unknown/user-modified
  content. It never installs or restores the
  login-shell export profile. Existing shells must be restarted to discard inherited
  environment snapshots.
- `update`: rebuild and restart an already-running daemon.

Repository verification:

```sh
python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
python3 modules/credproxy/tests/probe_credential_authority.py --self-test
python3 modules/credproxy/tests/probe_parent_env_names.py --report /tmp/parent-env-names.json
python3 modules/credproxy/tests/probe_installed_inventory.py --home /tmp/fake-home --installed-config /tmp/fake-home/.config/credproxyd/config.toml --report /tmp/inventory.json [--consumer-root /fixed/installed/source]
python3 -m unittest modules/editor-nvim/tests/test_minuet_credentialless.py
```
