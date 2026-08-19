#!/usr/bin/python3
"""Public initializer prerequisite は service 起動前に fail closedする。"""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1]


class SetupContractTests(unittest.TestCase):
	def test_systemd_unit_allows_state_and_snapshot_writes(self):
		unit = (MODULE / "assets/systemd/user/context-service.service").read_text(encoding="utf-8")
		self.assertIn("ProtectHome=read-only", unit)
		self.assertIn(
			"ReadWritePaths=%h/.local/state/context-fabric %h/.cache/context-fabric",
			unit,
		)

	def test_missing_public_cli_is_typed_nonzero_before_start(self):
		with tempfile.TemporaryDirectory() as raw:
			root = Path(raw)
			home = root / "home"
			dotfiles = root / "dotfiles"
			module = dotfiles / "modules/context-fabric-service"
			home.mkdir()
			shutil.copytree(MODULE, module)
			(dotfiles / "modules/_lib").mkdir(parents=True)
			(dotfiles / "modules/_lib/common.sh").write_text(
				'is_darwin() { return 1; }\n'
				'has_cmd() { return 1; }\n'
				'log() { printf "%s\\n" "$*" >&2; }\n', encoding="utf-8")
			(dotfiles / "modules/credproxy").mkdir(parents=True)
			shutil.copy2(MODULE.parent / "credproxy/socket-path.sh", dotfiles / "modules/credproxy/socket-path.sh")
			binary = home / ".local/lib/context-fabric/bin/context-service"
			binary.parent.mkdir(parents=True)
			binary.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
			binary.chmod(0o700)
			result = subprocess.run(
				["/usr/bin/env", "bash", str(module / "setup.sh")],
				env={"HOME": str(home), "PATH": "/usr/bin:/bin"},
				text=True, capture_output=True)
			self.assertEqual(result.returncode, 2)
			self.assertIn("client_cli_unavailable", result.stderr)


if __name__ == "__main__":
	unittest.main()
