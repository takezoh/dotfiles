#!/usr/bin/python3
"""Context Fabric service の installed copy 契約。"""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1]


class InstallManagementTests(unittest.TestCase):
	def setUp(self):
		self.temp = tempfile.TemporaryDirectory()
		self.root = Path(self.temp.name)
		self.home = self.root / "home"
		self.dotfiles = self.root / "dotfiles"
		self.module = self.dotfiles / "modules/context-fabric-service"
		self.fake_bin = self.root / "fake-bin"
		self.home.mkdir()
		self.fake_bin.mkdir()
		shutil.copytree(MODULE, self.module)
		(self.dotfiles / "modules/_lib").mkdir(parents=True)
		(self.dotfiles / "modules/_lib/common.sh").write_text(
			'has_cmd() { command -v "$1" >/dev/null 2>&1; }\n'
			'log() { printf "%s\\n" "$*" >&2; }\n', encoding="utf-8")

	def tearDown(self):
		self.temp.cleanup()

	def run_install(self, *, with_source=True, failing_go=False):
		if with_source:
			(self.root / "context-fabric/cmd/context-service").mkdir(parents=True)
		go = self.fake_bin / "go"
		if failing_go:
			go.write_text("#!/bin/sh\nexit 7\n", encoding="utf-8")
		else:
			go.write_text(
				'#!/bin/sh\nout=""\nwhile [ "$#" -gt 0 ]; do '
				'[ "$1" = -o ] && { shift; out="$1"; }; shift; done\n'
				'printf "#!/bin/sh\\nexit 0\\n" > "$out"\nchmod 0755 "$out"\n',
				encoding="utf-8")
		go.chmod(0o755)
		env = {
			"HOME": str(self.home), "DOTFILES_DIR": str(self.dotfiles),
			"PATH": f"{self.fake_bin}:/usr/bin:/bin",
		}
		return subprocess.run(
			["/usr/bin/env", "bash", str(self.module / "install.sh")],
			env=env, text=True, capture_output=True)

	def test_install_places_regular_executable_copy(self):
		result = self.run_install()
		self.assertEqual(result.returncode, 0, result.stderr)
		binary = self.home / ".local/lib/context-fabric/bin/context-service"
		self.assertTrue(binary.is_file())
		self.assertFalse(binary.is_symlink())
		self.assertTrue(os.access(binary, os.X_OK))

	def test_missing_source_is_typed_failure(self):
		result = self.run_install(with_source=False)
		self.assertEqual(result.returncode, 2)
		self.assertIn("source_unavailable", result.stderr)

	def test_failed_build_preserves_previous_installed_copy(self):
		binary = self.home / ".local/lib/context-fabric/bin/context-service"
		binary.parent.mkdir(parents=True)
		binary.write_bytes(b"previous-runtime")
		binary.chmod(0o700)
		result = self.run_install(failing_go=True)
		self.assertNotEqual(result.returncode, 0)
		self.assertEqual(binary.read_bytes(), b"previous-runtime")


if __name__ == "__main__":
	unittest.main()
