#!/usr/bin/python3
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class SecretSafePathTests(unittest.TestCase):
	def test_production_sources_use_only_the_protected_service_account_token(self):
		paths = [ROOT / "assets/hooks/op-resolve.py", ROOT / "assets/config.toml"]
		text = "\n".join(path.read_text() for path in paths)
		self.assertIn(".secrets/op/service-account.token", text)
		for forbidden in ("resolved.json", "auth_tokens_file", "CREDPROXY_RESOLVED_STORE", "CREDPROXY_OP_TOKEN_FILE"):
			self.assertNotIn(forbidden, text)

	def test_setup_inventories_legacy_material_by_presence_only(self):
		text = (ROOT / "setup.sh").read_text()
		for known in ("resolved.json", "$CONFIG_DIR/token", "anthropic_key", "grok-script-env"):
			self.assertIn(known, text)
		self.assertIn('provision-service-account-token.sh', text)
		for forbidden in ('cat "$candidate"', 'read_bytes', 'source "$candidate"'):
			self.assertNotIn(forbidden, text)

	def test_anthropic_binding_records_only_disabled_contract(self):
		binding = json.loads((ROOT / "assets/bindings/minuet-anthropic.json").read_text())
		self.assertEqual(binding["classification"], "provider_disabled")
		self.assertEqual(binding["operation"]["url"], "https://api.anthropic.com/v1/messages")
		self.assertFalse(binding["limits"]["automatic_retry"])

	def test_config_uses_protocol_injection_only(self):
		text = (ROOT / "assets/config.toml").read_text()
		self.assertIn('path = "/v1/sync/remote"', text)
		self.assertIn('upstream = "http://127.0.0.1:8480/v1/sync/remote"', text)
		self.assertNotIn('[[operation]]', text)
		self.assertNotIn('executable_paths', text)
		self.assertNotIn('path = "/anthropic"', text)
		self.assertNotIn('path = "/grok-x-search"', text)


if __name__ == "__main__": unittest.main()
