# credproxy (module)

Credential authority and protocol-injection wiring. Runtime assets are installed as
copies outside the workspace; credential material is never provisioned by this
repository and has no persistent plaintext fallback.

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
| Context Fabric remote sync | `POST /v1/sync/remote` is proxied to context-service; credproxy injects only the Context Fabric service bearer header. Context Fabric owns the operation. |
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

`context-service` is built from the sibling Context Fabric repository and installed
as a copy under `~/.local/lib/context-fabric/bin`. Its product-owned configuration is
`~/.config/context-fabric/service.json`; dotfiles does not render it or store a bearer.
The service principal entry contains only the SHA-256 of the bearer held by the
credential authority. A minimal local deployment also sets `listen` to
`127.0.0.1:8480`, an absolute `state_dir` and `snapshot_path`, and the remote source
definitions. Setup starts the packaged service and requires `/v1/healthz` before it
removes the legacy parent-env profile.

## Phases

- `install`: build the broker and Context Fabric service binaries; copy resolver,
  editor client, binding, service-manager assets, and proxy config.
  Config has a managed provenance sidecar and exact source/installed revisions;
  unknown, locally modified, or source-new/installed-old state is conflicting.
- `setup`: remove the exact known managed shell profile only after context-service
  health, managed proxy wiring, and the selected secure authority are available;
  stop on unknown/user-modified content. It never installs or restores the
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
