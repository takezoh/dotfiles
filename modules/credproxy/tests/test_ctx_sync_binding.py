#!/usr/bin/python3
"""Adversarial tests for the installed-form credroute/v1 ctx-sync/2 client."""
from __future__ import annotations

import hashlib
import json
import os
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

SOURCE_WRAPPER = Path(__file__).resolve().parents[1] / "assets/wrappers/ctx-sync"
INSTALL_SCRIPT = Path(__file__).resolve().parents[1] / "install.sh"
BINDING_TEMPLATE = Path(__file__).resolve().parents[1] / "assets/bindings/ctx-sync.json"


def identity(path: Path) -> dict[str, object]:
    info = path.stat()
    return {"path": str(path), "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "uid": info.st_uid, "mode": format(stat.S_IMODE(info.st_mode), "04o")}


class BindingFixture:
    def __init__(self, root: Path) -> None:
        self.home = root / "literal-home"
        self.runtime = self.home / ".local/lib/credproxy"
        self.bin_dir = self.runtime / "bin"
        self.binding_dir = self.runtime / "bindings"
        self.config_dir = self.home / ".config/credproxyd"
        self.output = root / "operation-observation.json"
        for directory in (self.bin_dir, self.binding_dir, self.config_dir):
            directory.mkdir(parents=True)
        self.wrapper = self.bin_dir / "ctx-sync"
        self.wrapper.write_bytes(SOURCE_WRAPPER.read_bytes())
        self.wrapper.chmod(0o755)
        self.credproxy = self.bin_dir / "credproxy"
        self.credproxy.write_text(
            "#!/usr/bin/python3\nimport json,os,sys\n"
            f"open({str(self.output)!r},'w').write(json.dumps({{'argv':sys.argv[1:],'credential_present':'CTX_DATABASE_URL' in os.environ,'env_names':sorted(os.environ)}}))\n",
            encoding="utf-8",
        )
        self.credproxy.chmod(0o755)
        self.ctx = self.bin_dir / "ctx"
        self.ctx.write_text("#!/bin/sh\nexit 88\n", encoding="utf-8")
        self.ctx.chmod(0o755)
        self.config = self.config_dir / "config.toml"
        self.config.write_text('daemon_revision="credproxyd/test"\n', encoding="utf-8")
        self.config.chmod(0o600)
        self.socket_path = root / "broker.sock"
        self.manifest_path = self.binding_dir / "ctx-sync.json"
        self.write_manifest()

    def write_manifest(self, mutate=None) -> None:
        manifest = {
            "schema": "credroute/v1", "binding_id": "ctx-sync", "binding_revision": "ctx-sync/2",
            "producer_revision": "test-revision", "client_revision": "client/1",
            "daemon_revision": "credproxyd/" + "a" * 64,
            "route": "ctx-sync", "credential_names": [], "subcommand": "sync",
            "argv_grammar": {"options": ["-timeout", "-min-interval"], "cardinality": "zero-or-one-each", "value": "go-duration", "positional": False, "separator": False},
            "broker": {"socket": str(self.socket_path), "config": identity(self.config), "home": str(self.home)},
            "base_env": {"HOME": str(self.home), "LANG": "C.UTF-8", "TZ": "UTC"},
            "executables": {"wrapper": identity(self.wrapper), "credproxy": identity(self.credproxy), "ctx": identity(self.ctx)},
        }
        if mutate:
            mutate(manifest)
        self.manifest_path.write_text(json.dumps(manifest), encoding="utf-8")

    def run(self, args=(), extra_env=None):
        env = {"HOME": "/caller/home", "PATH": "/caller/bin", "LANG": "ja_JP.UTF-8"}
        if extra_env:
            env.update(extra_env)
        return subprocess.run([str(self.wrapper), *args], env=env, capture_output=True, text=True, timeout=5)


class CtxSyncBindingTests(unittest.TestCase):
    def test_success_invokes_only_fixed_closed_operation_without_credential(self):
        with tempfile.TemporaryDirectory() as temp:
            fixture = BindingFixture(Path(temp))
            result = fixture.run(("-timeout", "1m30s", "-min-interval", "5m"))
            self.assertEqual(result.returncode, 0, result.stderr)
            observed = json.loads(fixture.output.read_text())
            self.assertEqual(observed["argv"], ["operation", "--socket", str(fixture.socket_path), "--route", "ctx-sync", "--binding-revision", "ctx-sync/2", "--daemon-revision", "credproxyd/" + "a" * 64, "--", "-timeout", "1m30s", "-min-interval", "5m"])
            self.assertFalse(observed["credential_present"])
            self.assertEqual(observed["env_names"], ["HOME", "LANG", "TZ"])

    def test_version_handshake_is_revisioned(self):
        with tempfile.TemporaryDirectory() as temp:
            result = BindingFixture(Path(temp)).run(("--credroute-version",))
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), "credroute/v1 ctx-sync/2 test-revision")

    def test_invalid_argv_is_preexec_rejected(self):
        for args in (("brief",), ("-timeout", "1s", "-timeout", "2s"), ("--",), ("-timeout", "forever")):
            with self.subTest(args=args), tempfile.TemporaryDirectory() as temp:
                fixture = BindingFixture(Path(temp))
                result = fixture.run(args)
                self.assertEqual(result.returncode, 64)
                self.assertFalse(fixture.output.exists())

    def test_identity_and_loader_mutations_are_preexec_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            fixture = BindingFixture(Path(temp))
            fixture.credproxy.write_text("#!/bin/sh\nexit 0\n")
            fixture.credproxy.chmod(0o755)
            result = fixture.run()
            self.assertEqual(result.returncode, 64)
            self.assertIn("binding_identity_mismatch", result.stderr)
        with tempfile.TemporaryDirectory() as temp:
            fixture = BindingFixture(Path(temp))
            result = fixture.run(extra_env={"PYTHONPATH": "/caller/runtime"})
            self.assertEqual(result.returncode, 64)
            self.assertIn("binding_env_invalid", result.stderr)

    def test_install_contract_uses_non_allowlisted_trusted_runtime(self):
        source = INSTALL_SCRIPT.read_text()
        self.assertIn('RUNTIME_ROOT="$HOME/.local/lib/credproxy"', source)
        self.assertNotIn('BIN_DIR="$HOME/.local/bin"', source)
        template = json.loads(BINDING_TEMPLATE.read_text().replace("@UID@", "1"))
        self.assertEqual(template["binding_revision"], "ctx-sync/2")
        self.assertEqual(template["client_revision"], "client/1")
        self.assertEqual(template["credential_names"], [])


if __name__ == "__main__": unittest.main()
