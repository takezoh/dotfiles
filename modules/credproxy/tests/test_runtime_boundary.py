#!/usr/bin/python3
"""credproxy module は broker/authority/route だけを所有する。"""
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1]
PROFILES = MODULE.parents[1] / "profiles"


class RuntimeBoundaryTests(unittest.TestCase):
	def test_credproxy_does_not_package_context_service(self):
		production = [MODULE / "install.sh", MODULE / "setup.sh", MODULE / "update.sh"]
		production.extend(
			path for path in (MODULE / "assets").rglob("*")
			if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc"
		)
		text = "\n".join(path.read_text() for path in production)
		for forbidden in ("CONTEXT_FABRIC_SRC", "CONTEXT_RUNTIME_ROOT", "context-service.service", "context-service.plist"):
			self.assertNotIn(forbidden, text)

	def test_host_profiles_order_runtime_before_proxy(self):
		for name in ("host-wsl.sh", "host-darwin.sh", "host-ubuntu-server.sh"):
			text = (PROFILES / name).read_text()
			self.assertLess(text.index("agent-module"), text.index("credproxy"), name)
			self.assertNotIn("context-fabric-service", text, name)

	def test_socket_template_has_one_platform_resolved_placeholder(self):
		config = (MODULE / "assets/config.toml").read_text()
		self.assertIn('@BROKER_SOCKET@', config)
		self.assertNotIn('/run/user/', config)
		install = (MODULE / "install.sh").read_text()
		resolver = (MODULE / "socket-path.sh").read_text()
		self.assertIn("broker_socket_path", install)
		self.assertIn("Library/Caches/credproxyd/runtime/credproxyd/broker.sock", resolver)
		self.assertIn("${XDG_RUNTIME_DIR:-/run/user/$uid}", resolver)
		self.assertIn("$runtime_dir/credproxyd/broker.sock", resolver)


if __name__ == "__main__":
	unittest.main()
