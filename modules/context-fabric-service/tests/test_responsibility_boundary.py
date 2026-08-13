#!/usr/bin/python3
"""Product config と OS lifecycle の ownership 境界。"""
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1]


class ResponsibilityBoundaryTests(unittest.TestCase):
	def test_module_does_not_own_product_config_or_sync(self):
		production = [path for path in MODULE.rglob("*") if path.is_file() and "tests" not in path.parts]
		text = "\n".join(path.read_text() for path in production)
		for forbidden in (
			'"principals"', '"token_sha256"', '"repos"', '"github"',
			"remote_sync_timeout_sec", "remote_sync_min_interval_sec",
			"POST /v1/sync/remote", "ctx principal",
		):
			self.assertNotIn(forbidden, text)

	def test_service_manager_uses_installed_copy_and_product_config(self):
		assets = "\n".join(path.read_text() for path in (MODULE / "assets").rglob("*") if path.is_file())
		self.assertIn(".local/lib/context-fabric/bin/context-service", assets)
		self.assertIn(".config/context-fabric/service.json", assets)
		self.assertNotIn("/workspace/", assets)

	def test_setup_delegates_config_projection_to_public_cli(self):
		setup = (MODULE / "setup.sh").read_text()
		self.assertIn('CTX="$HOME/.local/bin/ctx"', setup)
		self.assertIn('CLIENT_CONFIG="$HOME/.local/lib/context-fabric/client/.ctx/config.json"', setup)
		self.assertIn('"$CTX" service init', setup)
		for value in (
			'"$CLIENT_CONFIG"', '"$CONFIG"', '"$STATE_DIR"', '"$SNAPSHOT"',
			'"$PRINCIPALS"', '"$BROKER_SOCKET"', '"$DEPLOYMENT_TENANT"',
		):
			self.assertIn(value, setup)
		self.assertNotIn("json.dump", setup)
		self.assertLess(setup.index('"$CTX" service init'), setup.index("systemctl --user restart"))

	def test_service_path_can_resolve_gateway_helpers(self):
		assets = "\n".join(path.read_text() for path in (MODULE / "assets").rglob("*") if path.is_file())
		self.assertIn(".local/bin", assets)

	def test_deployment_tenant_has_one_explicit_choice(self):
		setup = (MODULE / "setup.sh").read_text()
		self.assertEqual(setup.count('DEPLOYMENT_TENANT="personal"'), 1)


if __name__ == "__main__":
	unittest.main()
