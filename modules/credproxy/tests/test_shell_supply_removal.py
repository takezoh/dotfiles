#!/usr/bin/env python3
"""D3 contract tests for removing login-shell credential supply."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


REPO_ROOT = Path(__file__).resolve().parents[3]
SETUP = REPO_ROOT / "modules/credproxy/setup.sh"
README = REPO_ROOT / "modules/credproxy/README.md"
LEGACY_SOURCE = REPO_ROOT / "modules/credproxy/assets/shellenv/credproxy-env.sh"
LEGACY_INSTALLED = Path(".local/config/zshrc/50_credproxy-env.zsh")
CREDENTIAL_NAMES = ("CTX_DATABASE_URL", "XAI_API_KEY", "ANTHROPIC_API_KEY")


def git(*args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
	return subprocess.run(
		["git", "-C", str(REPO_ROOT), *args],
		check=check,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
	)


def legacy_profile_bytes() -> bytes:
	return b"# legacy managed fixture\n"


class SetupSandbox:
	def __init__(self) -> None:
		self._tmp = tempfile.TemporaryDirectory()
		self.root = Path(self._tmp.name)
		self.home = self.root / "home"
		self.module = self.root / "modules/credproxy"
		(self.root / "modules/_lib").mkdir(parents=True)
		self.module.mkdir(parents=True)
		self.home.mkdir()
		shutil.copy2(SETUP, self.module / "setup.sh")
		(self.root / "modules/_lib/common.sh").write_text(
			"""#!/bin/sh
has_cmd() { [ "$1" = systemctl ] && return 1; command -v "$1" >/dev/null 2>&1; }
is_darwin() { [ "${TEST_DARWIN:-0}" = 1 ]; }
log() { printf '%s\\n' "$*" >&2; }
""",
			encoding="utf-8",
		)

	def close(self) -> None:
		self._tmp.cleanup()

	@property
	def installed(self) -> Path:
		return self.home / LEGACY_INSTALLED

	def run(self) -> subprocess.CompletedProcess[str]:
		env = {
			"HOME": str(self.home),
			"PATH": os.environ.get("PATH", "/usr/bin:/bin"),
			"XDG_CONFIG_HOME": str(self.home / ".config"),
			"TEST_DARWIN": "1" if getattr(self, "darwin", False) else "0",
		}
		return subprocess.run(
			["/usr/bin/env", "bash", str(self.module / "setup.sh")],
			check=False,
			text=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
			env=env,
		)

	def prepare_managed_gate(self) -> None:
		self.darwin = True
		assets = self.module / "assets"
		assets.mkdir()
		shutil.copy2(REPO_ROOT / "modules/credproxy/assets/config.toml", assets / "config.toml")
		config = self.home / ".config/credproxyd/config.toml"
		config.parent.mkdir(parents=True)
		config.write_text('daemon_revision = "credproxyd/test"\n')
		import hashlib
		installed_sha = hashlib.sha256(config.read_bytes()).hexdigest()
		template_sha = hashlib.sha256((assets / "config.toml").read_bytes()).hexdigest()
		config.with_name("config.toml.managed.json").write_text(json.dumps({
			"schema": "credproxy-managed-config/v1", "owner": "dotfiles:modules/credproxy",
			"source_revision": f"sha256:{installed_sha}", "installed_revision": f"sha256:{installed_sha}",
			"template_revision": f"sha256:{template_sha}",
		}))


class ShellSupplyRemovalTests(unittest.TestCase):
	def setUp(self) -> None:
		self.sandbox = SetupSandbox()

	def tearDown(self) -> None:
		self.sandbox.close()

	def test_runtime_admission_has_no_source_repository_pins(self) -> None:
		setup = SETUP.read_text(encoding="utf-8")
		for forbidden in ("PRE_REMOVAL_ADMISSION_REVISION", "DOTFILES_D2_EVIDENCE_REVISION",
			"CONTEXT_FABRIC_ADMISSION_REVISION", "CONTEXT_FABRIC_HOOK_SHA256"):
			self.assertNotIn(forbidden, setup)

	def test_source_asset_and_setup_install_instruction_are_absent(self) -> None:
		self.assertFalse(LEGACY_SOURCE.exists())
		setup = SETUP.read_text(encoding="utf-8")
		self.assertNotRegex(setup, r"\b(cp|install)\b[^\n]*credproxy-env\.sh")

	def test_linux_service_lifecycle_stops_on_authority_loss_and_restarts_on_update(self) -> None:
		setup = SETUP.read_text(encoding="utf-8")
		marker = "if ! has_cmd systemctl || [ ! -d /run/systemd/system ]"
		unsupported = setup.split(marker, 1)[1].split("if ! managed_config_ready", 1)[0]
		self.assertIn("disable --now credproxyd.service", unsupported)
		self.assertIn('bash "$MODULE_DIR/provision-service-account-token.sh"', setup)
		self.assertIn("systemctl --user enable credproxyd.service", setup)
		self.assertIn("systemctl --user restart credproxyd.service", setup)
		self.assertNotIn("systemctl --user enable --now credproxyd.service", setup)
		self.assertNotIn("assets/shellenv", setup)

	def test_managed_profile_is_preserved_until_consumer_admission(self) -> None:
		self.sandbox.installed.parent.mkdir(parents=True)
		self.sandbox.installed.write_bytes(legacy_profile_bytes())

		result = self.sandbox.run()

		self.assertEqual(result.returncode, 0)
		self.assertEqual(self.sandbox.installed.read_bytes(), legacy_profile_bytes())

	def test_profile_reconciliation_occurs_only_after_authority_and_service_health(self) -> None:
		setup = SETUP.read_text(encoding="utf-8")
		definition_end = setup.index("managed_config_ready()")
		call_sites = [match.start() for match in re.finditer(r"reconcile_legacy_shell_profile \|\| exit 2", setup)]
		self.assertEqual(len(call_sites), 2)
		self.assertTrue(all(site > definition_end for site in call_sites))
		self.assertLess(setup.index("find-generic-password"), call_sites[0])
		self.assertLess(
			setup.index('bash "$MODULE_DIR/provision-service-account-token.sh"'),
			call_sites[1],
		)
		self.assertIn("context_service_ready", setup)
		self.assertIn("http://127.0.0.1:8480/v1/healthz", setup)
		self.assertNotIn("consumer_admission_ready", setup)

	def test_user_modified_profile_is_conflicting_and_preserved(self) -> None:
		self.sandbox.installed.parent.mkdir(parents=True)
		user_content = b"# user-owned local shell configuration\n"
		self.sandbox.installed.write_bytes(user_content)

		result = self.sandbox.run()

		self.assertEqual(result.returncode, 0)
		self.assertEqual(self.sandbox.installed.read_bytes(), user_content)

	def test_unknown_symlink_profile_is_conflicting_and_preserved(self) -> None:
		target = self.sandbox.root / "user-profile"
		target.write_bytes(legacy_profile_bytes())
		self.sandbox.installed.parent.mkdir(parents=True)
		self.sandbox.installed.symlink_to(target)

		result = self.sandbox.run()

		self.assertEqual(result.returncode, 0)
		self.assertTrue(self.sandbox.installed.is_symlink())
		self.assertEqual(target.read_bytes(), legacy_profile_bytes())

	def test_absent_profile_stays_absent_and_is_never_restored(self) -> None:
		first = self.sandbox.run()
		second = self.sandbox.run()

		self.assertEqual(first.returncode, 0, first.stderr)
		self.assertEqual(second.returncode, 0, second.stderr)
		self.assertFalse(self.sandbox.installed.exists())
		self.assertIn("never installs or restores", README.read_text(encoding="utf-8"))

	def test_route_is_protocol_injection_without_command_binding(self) -> None:
		config = (REPO_ROOT / "modules/credproxy/assets/config.toml").read_text(encoding="utf-8")
		binding = REPO_ROOT / "modules/credproxy/assets/bindings/ctx-sync.json"
		wrapper = REPO_ROOT / "modules/credproxy/assets/wrappers/ctx-sync"
		self.assertIn('path = "/v1/sync/remote"', config)
		self.assertIn('strip_inbound_auth = true', config)
		self.assertNotIn('[[operation]]', config)
		self.assertFalse(binding.exists())
		self.assertFalse(wrapper.exists())

	def test_fresh_parent_probe_reports_names_as_booleans_only(self) -> None:
		probe = (
			"import json,os; names=" + repr(CREDENTIAL_NAMES)
			+ "; print(json.dumps({name: name in os.environ for name in names}, sort_keys=True))"
		)
		result = subprocess.run(
			["/usr/bin/env", "-i", "PATH=/usr/bin:/bin", "/usr/bin/python3", "-c", probe],
			check=True,
			text=True,
			stdout=subprocess.PIPE,
			stderr=subprocess.PIPE,
		)
		observed = json.loads(result.stdout)
		self.assertEqual(observed, {name: False for name in CREDENTIAL_NAMES})
		self.assertTrue(all(type(value) is bool for value in observed.values()))
		self.assertFalse(re.search(r"(?i)(token|secret|password)", result.stdout))

	def test_mixed_persistent_material_fixture_blocks_cutover_without_reading_values(self) -> None:
		self.sandbox.prepare_managed_gate()
		paths = {
			"resolved-store": self.sandbox.home / ".secrets/credproxyd/resolved.json",
			"broker-token": self.sandbox.home / ".config/credproxyd/token",
			"grok-env-copy": self.sandbox.home / ".secrets/env/skills-grok-x-search-scripts",
			"grok-env": self.sandbox.home / ".grok/.env",
			"grok-config-env": self.sandbox.home / ".config/grok/.env",
			"grok-secret-env": self.sandbox.home / ".secrets/grok.env",
			"anthropic-key": self.sandbox.home / ".secrets/anthropic_key",
			"grok-script-env": self.sandbox.home / ".codex/plugins/cache/a/b/skills/grok-x-search/scripts/.env",
		}
		for path in paths.values():
			path.parent.mkdir(parents=True, exist_ok=True)
			path.write_text("NONSECRET_TEST_CANARY_MUST_NOT_BE_REPORTED")
		result = self.sandbox.run()
		self.assertEqual(result.returncode, 2)
		for label in paths:
			self.assertIn(label, result.stderr)
		self.assertNotIn("NONSECRET_TEST_CANARY", result.stderr)


if __name__ == "__main__":
	unittest.main()
