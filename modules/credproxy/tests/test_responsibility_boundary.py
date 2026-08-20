#!/usr/bin/python3
import unittest
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]


class ResponsibilityBoundaryTests(unittest.TestCase):
	def test_current_docs_keep_context_runtime_in_agent_module(self):
		readme = (MODULE / "README.md").read_text()
		design = (
			MODULE.parents[1]
			/ "docs/design/design-credential-integration-wiring-boundary.md"
		).read_text()
		for text in (readme, design):
			self.assertIn("agent-module", text)
			self.assertNotIn("sibling `context-fabric-service`", text)
			self.assertNotIn("separate context-fabric-service", text)

	def test_dotfiles_owns_wiring_not_consumer_command_policy(self):
		production = [MODULE / "install.sh", MODULE / "setup.sh"]
		production.extend(
			path for path in (MODULE / "assets").rglob("*")
			if path.is_file() and path.suffix in {".sh", ".py", ".toml", ".json", ".plist", ".service", ".conf"}
		)
		text = "\n".join(path.read_text() for path in production)
		for forbidden in (
			"[[operation]]", "executable_paths", "ctx-sync/2",
			"PRE_REMOVAL_ADMISSION_REVISION", "CONTEXT_FABRIC_ADMISSION_REVISION",
			"CONTEXT_FABRIC_HOOK_SHA256",
		):
			self.assertNotIn(forbidden, text)
		self.assertIn('path = "/v1/sync/remote"', text)
		self.assertIn('upstream = "http://127.0.0.1:8480/v1/sync/remote"', text)
		self.assertIn('credential_command = ["@HOOK_PATH@"]', text)
		self.assertNotIn('[route.onepassword]', text)

	def test_obsolete_closed_operation_assets_are_absent(self):
		self.assertFalse((MODULE / "assets/wrappers/ctx-sync").exists())
		self.assertFalse((MODULE / "assets/bindings/ctx-sync.json").exists())


if __name__ == "__main__":
	unittest.main()
