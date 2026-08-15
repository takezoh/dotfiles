#!/usr/bin/python3
"""Secret-safe exact-revision authority probe using only fake material."""
from __future__ import annotations

import argparse
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

SCHEMA = "credential-authority/v1"
MANDATORY = ("mechanism_available", "fixed_resolver", "child_only_injection", "restart_revocation", "negative_captures", "persistent_absence")
CANARY = "NONSECRET_TEST_CANARY_AUTHORITY"
RESOLVER_PATH = Path(__file__).resolve().parents[1] / "assets/hooks/op-resolve.py"
SYSTEMD_UNIT_PATH = Path(__file__).resolve().parents[1] / "assets/systemd/user/credproxyd.service"
sys.dont_write_bytecode = True


def load_resolver():
	spec = importlib.util.spec_from_file_location("op_resolve", RESOLVER_PATH)
	module = importlib.util.module_from_spec(spec)
	assert spec.loader
	spec.loader.exec_module(module)
	return module


def classify(cases: dict[str, str]) -> str:
	if set(cases) != set(MANDATORY):
		return "inconclusive"
	if cases["persistent_absence"] == "fail":
		return "conflicting"
	if cases["mechanism_available"] == "unsupported" or "fail" in cases.values():
		return "unsupported"
	if "not_observed" in cases.values():
		return "inconclusive"
	return "supported"


def fake_probe(platform_name: str, producer_revision: str) -> dict[str, object]:
	resolver = load_resolver()
	observed: dict[str, object] = {"tokens": [], "revoked": False}
	cases = {name: "pass" for name in MANDATORY}
	with tempfile.TemporaryDirectory() as temp:
		home = Path(temp) / "home"
		authority = home / ".secrets/op/service-account.token"
		authority.parent.mkdir(parents=True)
		(home / ".secrets").chmod(0o700)
		authority.parent.chmod(0o700)
		authority.write_text(CANARY, encoding="utf-8")
		authority.chmod(0o600)

		def fake_read(path: Path) -> bytes:
			observed["runtime_path"] = str(path.relative_to(home))
			if observed["revoked"]:
				raise FileNotFoundError(path)
			return authority.read_bytes()

		def fake_security(argv, **kwargs):
			observed["security_argv"] = argv
			if observed["revoked"]:
				return subprocess.CompletedProcess(argv, 44, "", "not found")
			return subprocess.CompletedProcess(argv, 0, authority.read_text() + "\n", "")

		def fake_op(argv, **kwargs):
			env = kwargs["env"]
			observed["op_argv"] = argv
			observed["op_env_names"] = sorted(env)
			observed["tokens"].append(env.get("OP_SERVICE_ACCOUNT_TOKEN") == CANARY)
			return subprocess.CompletedProcess(argv, 0, "NONSECRET_RESOLVED_VALUE", "")

		out, err = io.StringIO(), io.StringIO()
		with redirect_stdout(out), redirect_stderr(err):
			for _ in range(2):
				resolver.resolve_request(
					{"route": "v1/sync/remote"}, platform_name=platform_name,
					environ={"HOME": str(home)},
					read_bytes=fake_read, run_security=fake_security, run_op=fake_op,
				)
			observed["revoked"] = True
			try:
				resolver.resolve_request(
					{"route": "v1/sync/remote"}, platform_name=platform_name,
					environ={"HOME": str(home)},
					read_bytes=fake_read, run_security=fake_security, run_op=fake_op,
				)
			except SystemExit:
				observed["revocation_failed_closed"] = True
		for forbidden in ("resolved.json", "token"):
			if (Path(temp) / forbidden).exists():
				cases["persistent_absence"] = "fail"
		capture = json.dumps({"stdout": out.getvalue(), "stderr_categories": err.getvalue().splitlines()})
		if CANARY in capture:
			cases["negative_captures"] = "fail"
	if observed.get("tokens") != [True, True] or observed.get("op_env_names") != ["HOME", "LANG", "OP_SERVICE_ACCOUNT_TOKEN"]:
		cases["child_only_injection"] = "fail"
	if not observed.get("revocation_failed_closed"):
		cases["restart_revocation"] = "fail"
	if platform_name == "linux" and observed.get("runtime_path") != ".secrets/op/service-account.token":
		cases["fixed_resolver"] = "fail"
	if platform_name == "darwin" and observed.get("security_argv", [])[:2] != ["/usr/bin/security", "find-generic-password"]:
		cases["fixed_resolver"] = "fail"
	return {
		"schema": SCHEMA, "runner_revision": producer_revision, "platform": platform_name,
		"mechanism": "protected-local-secret" if platform_name == "linux" else "login-keychain-fixed-item",
		"cases": cases, "classification": classify(cases), "route_enabled": classify(cases) == "supported",
		"fallback": "none", "credential_material_observed": False,
	}


class AuthorityProbeTests(unittest.TestCase):
	def test_linux_and_macos_fake_paths_are_supported_without_capture(self):
		for name in ("linux", "darwin"):
			with self.subTest(name=name):
				report = fake_probe(name, "test-revision")
				self.assertEqual(report["classification"], "supported")
				self.assertNotIn(CANARY, json.dumps(report))

	def test_resolver_has_no_persistent_fallback_tokens(self):
		source = RESOLVER_PATH.read_text()
		for forbidden in ("resolved.json", "CREDPROXY_RESOLVED_STORE", "CREDPROXY_OP_TOKEN_FILE"):
			self.assertNotIn(forbidden, source)

	def test_missing_runtime_authority_is_typed_unavailable(self):
		resolver = load_resolver()
		stderr = io.StringIO()
		with redirect_stderr(stderr), self.assertRaises(SystemExit):
			resolver.authority_token("linux", {})
		self.assertEqual(stderr.getvalue(), "reason:credential_source_unavailable\n")

	def test_linux_unit_reads_only_protected_token_and_home_is_read_only(self):
		unit = SYSTEMD_UNIT_PATH.read_text(encoding="utf-8")
		self.assertNotIn("LoadCredential", unit)
		self.assertIn("ConditionPathExists=%h/.secrets/op/service-account.token", unit)
		self.assertIn("ProtectHome=read-only", unit)
		self.assertIn("credproxyd --config", unit)

	def test_native_op_failures_are_typed_without_exposing_stderr(self):
		resolver = load_resolver()
		for raw, expected in (
			("service account is not authorized for this vault", "vault_denied"),
			("invalid service account token", "credential_source_unavailable"),
			("failed to load requested vault", "vault_denied"),
			("service account validation failed", "credential_source_unavailable"),
		):
			with self.subTest(expected=expected):
				def fake_op(argv, **kwargs):
					return subprocess.CompletedProcess(argv, 1, "", raw)
				stderr = io.StringIO()
				with redirect_stderr(stderr), self.assertRaises(SystemExit):
					resolver.op_read("op://fixed/item/field", CANARY, run=fake_op)
				self.assertEqual(stderr.getvalue(), f"reason:{expected}\n")
				self.assertNotIn(raw, stderr.getvalue())

	def test_linux_authority_rejects_symlinked_parent_directory(self):
		resolver = load_resolver()
		with tempfile.TemporaryDirectory() as temp:
			home = Path(temp) / "home"
			target = Path(temp) / "target"
			home.mkdir()
			(home / ".secrets").mkdir(mode=0o700)
			target.mkdir(mode=0o700)
			(target / "service-account.token").write_text(CANARY)
			(target / "service-account.token").chmod(0o600)
			(home / ".secrets/op").symlink_to(target, target_is_directory=True)
			stderr = io.StringIO()
			with redirect_stderr(stderr), self.assertRaises(SystemExit):
				resolver.authority_token("linux", {"HOME": str(home)})
			self.assertEqual(stderr.getvalue(), "reason:credential_source_unavailable\n")


def main():
	parser = argparse.ArgumentParser()
	parser.add_argument("--report", type=Path)
	parser.add_argument("--producer-revision", required=False, default="uncommitted")
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
