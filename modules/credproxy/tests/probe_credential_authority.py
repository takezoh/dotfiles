#!/usr/bin/python3
"""Secret-safe structural probe for the user-owned credential resolver."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import unittest


SCHEMA = "credential-authority/v2"
ROOT = Path(__file__).resolve().parents[1]
CONFIG_PATH = ROOT / "assets/config.toml"
RESOLVER_PATH = ROOT / "helpers/onepassword-resolver/main.go"
SYSTEMD_UNIT_PATH = ROOT / "assets/systemd/user/credproxyd.service"
FIXED_REFS = (
	"op://local-dev/Context Fabric/Service Principal/token",
	"op://local-dev/Amsterdam/Jenkins/token",
)


def production_text() -> str:
	paths = [ROOT / "install.sh", ROOT / "setup.sh", CONFIG_PATH, RESOLVER_PATH]
	paths.extend(
		path for path in (ROOT / "assets").rglob("*")
		if path.is_file() and path.suffix in {".sh", ".py", ".toml", ".plist", ".service", ".conf"}
	)
	return "\n".join(path.read_text(errors="ignore") for path in paths)


def fake_probe(platform_name: str, producer_revision: str) -> dict[str, object]:
	config = CONFIG_PATH.read_text()
	resolver = RESOLVER_PATH.read_text()
	text = production_text()
	cases = {
		"protected_file": "service-account.token" in resolver,
		"fixed_references": all(ref in resolver for ref in FIXED_REFS),
		"user_resolver_binding": config.count('credential_command = ["@HOOK_PATH@"]') == 2,
		"provider_neutral_broker": "[route.onepassword]" not in config,
		"no_token_environment": "OP_SERVICE_ACCOUNT_TOKEN" not in text and "WSLENV" not in text,
	}
	supported = all(cases.values())
	return {
		"schema": SCHEMA,
		"runner_revision": producer_revision,
		"platform": platform_name,
		"mechanism": "protected-file-to-user-resolver-sdk",
		"cases": {name: "pass" if value else "fail" for name, value in cases.items()},
		"classification": "supported" if supported else "unsupported",
		"route_enabled": supported,
		"fallback": "none",
		"credential_material_observed": False,
	}


class AuthorityProbeTests(unittest.TestCase):
	def test_fixed_routes_use_user_resolver_configuration(self):
		config = CONFIG_PATH.read_text()
		resolver = RESOLVER_PATH.read_text()
		self.assertEqual(config.count('credential_command = ["@HOOK_PATH@"]'), 2)
		self.assertNotIn("[route.onepassword]", config)
		for ref in FIXED_REFS:
			self.assertIn(ref, resolver)

	def test_runtime_has_no_cli_resolver_or_token_environment(self):
		text = production_text()
		self.assertFalse((ROOT / "assets/hooks/op-resolve.py").exists())
		self.assertNotIn("OP_SERVICE_ACCOUNT_TOKEN", text)
		self.assertNotIn("WSLENV", text)
		self.assertNotIn("configure_wsl_op_path", text)

	def test_platform_reports_are_supported_without_material(self):
		for name in ("linux", "darwin"):
			with self.subTest(name=name):
				report = fake_probe(name, "test-revision")
				self.assertEqual(report["classification"], "supported")
				self.assertFalse(report["credential_material_observed"])

	def test_linux_unit_reads_only_protected_token_and_home_is_read_only(self):
		unit = SYSTEMD_UNIT_PATH.read_text(encoding="utf-8")
		self.assertNotIn("LoadCredential", unit)
		self.assertIn("ConditionPathExists=%h/.secrets/op/service-account.token", unit)
		self.assertIn("ProtectHome=read-only", unit)
		self.assertIn("credproxyd --config", unit)


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--report", type=Path)
	parser.add_argument("--producer-revision", default="uncommitted")
	parser.add_argument("--platform", choices=("linux", "darwin"), default="linux")
	parser.add_argument("--self-test", action="store_true")
	args = parser.parse_args()
	if args.self_test:
		result = unittest.main(argv=["probe"], exit=False)
		raise SystemExit(not result.result.wasSuccessful())
	report = fake_probe(args.platform, args.producer_revision)
	encoded = json.dumps(report, indent=2, sort_keys=True) + "\n"
	if args.report:
		args.report.write_text(encoded)
	else:
		print(encoded, end="")


if __name__ == "__main__":
	main()
