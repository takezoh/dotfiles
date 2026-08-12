# credproxy (module)

Command-bound credential delivery for fixed consumers. Runtime assets are
installed as copies outside the workspace; credential material is never
provisioned by this repository and has no persistent plaintext fallback.

## Authority branches

- Linux/WSL: `LoadCredentialEncrypted=op-service-account:…` decrypts an
  operator-provisioned encrypted blob into systemd's service-private
  `$CREDENTIALS_DIRECTORY`. The resolver passes it only to the fixed native
  `/usr/local/bin/op read --no-newline <fixed-ref>` child.
- macOS: the resolver invokes fixed `/usr/bin/security` for service
  `com.takezoh.credproxy.op-service-account`, account `credproxyd`, then passes
  the result only to the fixed `op` child.
- Any other/missing/stale mechanism: `credential_source_unavailable`; setup
  disables the daemon/route. There is no file or environment fallback.

The operator creates the encrypted systemd credential or Keychain item outside
this module. Tests use only fake, nonsecret material. Do not place credential
values, prefixes, hashes, lengths, or canaries in reports.

## Consumer disposition

| Consumer | Outcome |
|---|---|
| `ctx sync` | retained through installed `credroute/v1` / `ctx-sync/2` closed-operation wrapper; the daemon injects `CTX_DATABASE_URL` only into the fixed `ctx sync` child and never returns it to the wrapper |
| Minuet / Anthropic | provider disabled: current credproxyd cannot prove executable-bound caller admission plus exact `POST https://api.anthropic.com/v1/messages`; no adapter/key callback/env fallback |
| grok-x-search / XAI | legacy key route retired from revision-matched OAuth-only consumer proof; generic env delivery and ctx route remain |

The legacy login-shell export asset and its setup copy were removed after the
D2 evidence checkpoint and the revision-bound removal admission. `setup`
reconciles only the exact D2 managed installed profile (fixed path, owner,
regular-file provenance, and checksum). Unknown or user-modified content is
left in place and reported as `conflicting`; migration stops instead of
deleting user state.

The installed `ctx sync` binding calls only `credproxy operation --socket
<fixed> --route ctx-sync --binding-revision ctx-sync/2 -- ...`. Runtime
identities are install-time copies under `~/.local/lib/credproxy`; service
definitions use those literal paths. They are not placed in the sandbox
allowlist.

## Phases

- `install`: build binaries; copy resolver, fixed clients, bindings, and config.
  Config has a managed provenance sidecar and exact source/installed revisions;
  unknown, locally modified, or source-new/installed-old state is conflicting.
- `setup`: remove an exact known D2 managed shell profile if present; stop on
  unknown/user-modified content; package the platform service; enable only when
  the selected secure authority is present. It never installs or restores the
  login-shell export profile.
- `update`: rebuild and restart an already-running daemon.

Repository verification:

```sh
python3 -m unittest discover -s modules/credproxy/tests -p 'test_*.py'
python3 modules/credproxy/tests/probe_credential_authority.py --self-test
python3 modules/credproxy/tests/probe_parent_env_names.py --report /tmp/parent-env-names.json
python3 modules/credproxy/tests/probe_installed_inventory.py --home /tmp/fake-home --installed-config /tmp/fake-home/.config/credproxyd/config.toml --report /tmp/inventory.json [--consumer-root /fixed/installed/source]
python3 -m unittest modules/editor-nvim/tests/test_minuet_credentialless.py
```
