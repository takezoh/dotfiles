#!/usr/bin/python3
"""Real-binary packaging E2E for the ctx-sync/2 closed operation."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import signal
import socket
import stat
import subprocess
import tempfile
import time
import unittest
import uuid
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
WRAPPER_SOURCE = MODULE / "assets/wrappers/ctx-sync"
CONFIG_SOURCE = MODULE / "assets/config.toml"
BINDING_SOURCE = MODULE / "assets/bindings/ctx-sync.json"
CORE = Path(os.environ.get("CREDPROXY_CORE_DIR", "/workspace/credproxy"))
EXPECTED_CORE_REVISION = os.environ.get(
    "CREDPROXY_CORE_REVISION", "cbe0d235e4412d12b01f7cdbcaa5577ad2595313"
)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def identity(path: Path) -> dict[str, object]:
    info = path.stat()
    return {
        "path": str(path), "sha256": digest(path), "uid": info.st_uid,
        "mode": format(stat.S_IMODE(info.st_mode), "04o"),
    }


def assert_secret_absent(testcase: unittest.TestCase, secret: str, value: str) -> None:
    testcase.assertNotIn(secret, value)


def unix_http(socket_path: Path, request: bytes) -> bytes:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        client.settimeout(2)
        client.connect(str(socket_path))
        client.sendall(request)
        chunks = []
        while True:
            chunk = client.recv(8192)
            if not chunk:
                return b"".join(chunks)
            chunks.append(chunk)
    finally:
        client.close()


class ClosedOperationE2E(unittest.TestCase):
    def test_real_daemon_wrapper_and_client_never_return_credential(self):
        if not (CORE / "go.mod").is_file():
            self.fail(f"credproxy core unavailable: {CORE}")
        revision = subprocess.run(
            ["git", "-C", str(CORE), "rev-parse", "HEAD"],
            check=True, capture_output=True, text=True,
        ).stdout.strip()
        self.assertEqual(revision, EXPECTED_CORE_REVISION)
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            runtime = root / "home/.local/lib/credproxy"
            binary = runtime / "bin"
            binding_dir = runtime / "bindings"
            hooks = runtime / "hooks"
            config_dir = root / "home/.config/credproxyd"
            for directory in (binary, binding_dir, hooks, config_dir):
                directory.mkdir(parents=True)

            credproxy = binary / "credproxy"
            daemon = binary / "credproxyd"
            subprocess.run(["go", "build", "-o", str(credproxy), "./cmd/credproxy"], cwd=CORE, check=True)
            subprocess.run(["go", "build", "-o", str(daemon), "./cmd/credproxyd"], cwd=CORE, check=True)
            self.assertEqual(
                subprocess.run([str(credproxy), "--credroute-version"], check=True, capture_output=True, text=True).stdout.strip(),
                "credroute/v1 ctx-sync/2 client/1",
            )

            secret = "opaque-" + uuid.uuid4().hex
            observation = root / "child-observation.json"
            resolver = hooks / "op-resolve.py"
            provider_response = json.dumps({"body_replace": {"env": {"CTX_DATABASE_URL": secret}}})
            resolver.write_text(
                "#!/usr/bin/python3\nimport json,sys\njson.load(sys.stdin)\n"
                + f"sys.stdout.write({provider_response!r})\n",
                encoding="utf-8",
            )
            resolver.chmod(0o755)
            ctx = binary / "ctx"
            ctx.write_text(
                "#!/usr/bin/python3\nimport json,os,sys\n"
                + f"open({str(observation)!r},'w').write(json.dumps({{'credential_present':'CTX_DATABASE_URL' in os.environ,'argv':sys.argv[1:]}}))\n"
                + "sys.stderr.write(os.environ.get('CTX_DATABASE_URL',''))\n",
                encoding="utf-8",
            )
            ctx.chmod(0o755)
            wrapper = binary / "ctx-sync"
            shutil.copyfile(WRAPPER_SOURCE, wrapper)
            wrapper.chmod(0o755)

            daemon_revision = "credproxyd/" + digest(daemon)
            socket_path = root / "broker.sock"
            config = config_dir / "config.toml"
            rendered = CONFIG_SOURCE.read_text(encoding="utf-8")
            replacements = {
                "@DAEMON_REVISION@": digest(daemon), "@BROKER_SOCKET@": str(socket_path),
                "@CTX_PATH@": str(ctx), "@HOOK_PATH@": str(resolver),
                "@CTX_CONFIG@": str(root / "home/.config/context-fabric/config.toml"),
            }
            for old, new in replacements.items():
                rendered = rendered.replace(old, new)
            config.write_text(rendered, encoding="utf-8")
            config.chmod(0o600)

            manifest_text = BINDING_SOURCE.read_text(encoding="utf-8")
            values = {
                "@DOTFILES_REVISION@": "e2e-producer", "@DAEMON_REVISION@": digest(daemon),
                "@BROKER_SOCKET@": str(socket_path), "@CONFIG_FILE@": str(config),
                "@CONFIG_SHA256@": digest(config), "@HOME@": str(root / "home"),
                "@WRAPPER_PATH@": str(wrapper), "@WRAPPER_SHA256@": digest(wrapper),
                "@CREDPROXY_PATH@": str(credproxy), "@CREDPROXY_SHA256@": digest(credproxy),
                "@CREDPROXY_MODE@": "0755", "@CTX_PATH@": str(ctx),
                "@CTX_SHA256@": digest(ctx), "@CTX_MODE@": "0755", "@UID@": str(os.getuid()),
            }
            for old, new in values.items():
                manifest_text = manifest_text.replace(old, new)
            manifest = binding_dir / "ctx-sync.json"
            manifest.write_text(manifest_text, encoding="utf-8")
            manifest.chmod(0o600)
            manifest_value = json.loads(manifest_text)
            for name, expected_identity in manifest_value["executables"].items():
                self.assertEqual(identity(Path(expected_identity["path"])), expected_identity, name)
            self.assertEqual(identity(config), manifest_value["broker"]["config"])

            process = subprocess.Popen(
                [str(daemon), "--config", str(config)], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                env={"HOME": str(root / "home"), "LANG": "C.UTF-8", "PATH": "/usr/bin:/bin"},
            )
            try:
                for _ in range(100):
                    if socket_path.exists():
                        break
                    if process.poll() is not None:
                        break
                    time.sleep(0.03)
                self.assertTrue(socket_path.exists(), process.stderr.read() if process.poll() is not None else "socket unavailable")
                result = subprocess.run(
                    [str(wrapper), "-timeout", "30s", "-min-interval", "0s"],
                    capture_output=True, text=True, timeout=10,
                    env={"HOME": "/caller/bait", "PATH": "/caller/bait", "LANG": "C.UTF-8"},
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                response = json.loads(result.stdout)
                self.assertEqual(set(response), {"protocol", "binding_revision", "daemon_revision", "operation", "outcome"})
                self.assertEqual(response["outcome"], "success")
                observed = json.loads(observation.read_text(encoding="utf-8"))
                self.assertTrue(observed["credential_present"])
                self.assertEqual(observed["argv"], ["sync", "-timeout", "30s", "-min-interval", "0s"])

                routes = unix_http(socket_path, b"GET /_routes HTTP/1.1\r\nHost: credproxyd\r\nConnection: close\r\n\r\n")
                direct = unix_http(socket_path, b"GET /ctx-sync HTTP/1.1\r\nHost: credproxyd\r\nConnection: close\r\n\r\n")
                captures = result.stdout + result.stderr + routes.decode(errors="replace") + direct.decode(errors="replace")
                assert_secret_absent(self, secret, captures)
                self.assertNotIn(b"ctx-sync", routes.split(b"\r\n\r\n", 1)[-1])
                self.assertIn(b"404", direct.split(b"\r\n", 1)[0])
                with self.assertRaises(AssertionError):
                    assert_secret_absent(self, secret, captures + secret)
            finally:
                process.send_signal(signal.SIGTERM)
                try:
                    daemon_stdout, daemon_stderr = process.communicate(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
                    daemon_stdout, daemon_stderr = process.communicate(timeout=5)
                assert_secret_absent(self, secret, daemon_stdout + daemon_stderr)


if __name__ == "__main__":
    unittest.main()
