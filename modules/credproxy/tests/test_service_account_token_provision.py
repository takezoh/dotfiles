#!/usr/bin/env python3
"""1Passwordからprotected local service-account tokenを生成する境界test。"""

from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT = REPO_ROOT / "modules/credproxy/provision-service-account-token.sh"
CANARY = "NONSECRET_TEST_SERVICE_ACCOUNT_TOKEN"


class ProvisionSandbox:
	def __init__(self) -> None:
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		self.home = self.root / "home"
		self.bin = self.root / "bin"
		self.home.mkdir()
		self.bin.mkdir()
		self.op_calls = self.root / "op-calls"
		self.op = self.bin / "op"
		self.op.write_text(
			f'''#!/bin/sh
printf '%s\\n' call >>"{self.op_calls}"
[ "$1" = read ] || exit 64
[ "$2" = --no-newline ] || exit 64
[ "$3" = 'op://Personal/4h3467uq736jjlju6xkeu6uvyq/credential' ] || exit 64
[ "${{TEST_OP_FAIL:-0}}" = 0 ] || exit 69
printf %s '{CANARY}'
''',
			encoding="utf-8",
		)
		self.op.chmod(0o755)
		self.script = self.root / "provision-service-account-token.sh"
		text = SCRIPT.read_text(encoding="utf-8")
		text = text.replace('readonly NATIVE_OP_BIN="/usr/local/bin/op"', f'readonly NATIVE_OP_BIN="{self.op}"')
		text = text.replace("readonly TRUSTED_BIN_UID=0", f"readonly TRUSTED_BIN_UID={os.getuid()}")
		text = text.replace('readonly WSL_MARKER="/mnt/c/Windows"', f'readonly WSL_MARKER="{self.root / "not-wsl"}"')
		self.script.write_text(text, encoding="utf-8")
		self.script.chmod(0o755)

	def close(self) -> None:
		self._tmp.cleanup()

	@property
	def token(self) -> Path:
		return self.home / ".secrets/op/service-account.token"

	def prepare_protected_directory(self) -> None:
		self.token.parent.mkdir(parents=True)
		(self.home / ".secrets").chmod(0o700)
		self.token.parent.chmod(0o700)

	def run(self, *args: str, extra_env: dict[str, str] | None = None) -> subprocess.CompletedProcess[str]:
		env = {"HOME": str(self.home), "PATH": "/usr/bin:/bin"}
		env.update(extra_env or {})
		return subprocess.run(
			["/usr/bin/env", "bash", str(self.script), *args],
			check=False,
			text=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			env=env,
		)


class ServiceAccountTokenProvisionTests(unittest.TestCase):
	def setUp(self) -> None:
		self.sandbox = ProvisionSandbox()

	def tearDown(self) -> None:
		self.sandbox.close()

	def test_token_is_written_only_to_protected_store(self) -> None:
		result = self.sandbox.run()

		self.assertEqual(result.returncode, 0, result.stderr)
		self.assertEqual(self.sandbox.token.read_text(), CANARY)
		self.assertEqual(self.sandbox.token.stat().st_mode & 0o777, 0o600)
		self.assertEqual(self.sandbox.token.parent.stat().st_mode & 0o777, 0o700)
		self.assertNotIn(CANARY, result.stdout + result.stderr)

	def test_existing_valid_token_is_reused_without_human_auth(self) -> None:
		self.sandbox.prepare_protected_directory()
		self.sandbox.token.write_text("EXISTING_TOKEN")
		self.sandbox.token.chmod(0o600)

		result = self.sandbox.run()

		self.assertEqual(result.returncode, 0, result.stderr)
		self.assertEqual(self.sandbox.token.read_text(), "EXISTING_TOKEN")
		self.assertFalse(self.sandbox.op_calls.exists())

	def test_failed_refresh_preserves_existing_token(self) -> None:
		self.sandbox.prepare_protected_directory()
		self.sandbox.token.write_text("EXISTING_TOKEN")
		self.sandbox.token.chmod(0o600)

		result = self.sandbox.run("--refresh", extra_env={"TEST_OP_FAIL": "1"})

		self.assertEqual(result.returncode, 3)
		self.assertEqual(self.sandbox.token.read_text(), "EXISTING_TOKEN")
		self.assertNotIn(CANARY, result.stdout + result.stderr)

	def test_symlink_token_is_conflicting_and_target_is_preserved(self) -> None:
		target = self.sandbox.root / "user-owned"
		target.write_text("USER_OWNED")
		self.sandbox.prepare_protected_directory()
		self.sandbox.token.symlink_to(target)

		result = self.sandbox.run()

		self.assertEqual(result.returncode, 2)
		self.assertEqual(target.read_text(), "USER_OWNED")
		self.assertFalse(self.sandbox.op_calls.exists())

	def test_existing_insecure_directory_mode_is_conflicting_and_preserved(self) -> None:
		self.sandbox.prepare_protected_directory()
		self.sandbox.token.write_text("EXISTING_TOKEN")
		self.sandbox.token.chmod(0o600)
		self.sandbox.token.parent.chmod(0o755)

		result = self.sandbox.run()

		self.assertEqual(result.returncode, 2)
		self.assertEqual(self.sandbox.token.parent.stat().st_mode & 0o777, 0o755)
		self.assertEqual(self.sandbox.token.read_text(), "EXISTING_TOKEN")
		self.assertFalse(self.sandbox.op_calls.exists())

	def test_wsl_bootstrap_invokes_the_path_resolved_op_wrapper(self) -> None:
		text = SCRIPT.read_text(encoding="utf-8")
		self.assertIn('candidate="$(command -v op 2>/dev/null || true)"', text)
		self.assertIn("printf '%s\\n' op", text)


if __name__ == "__main__":
	unittest.main()
