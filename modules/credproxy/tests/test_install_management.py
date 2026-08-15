#!/usr/bin/python3
"""Executable install fixtures for trusted packaging and config provenance."""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
REPO = MODULE.parents[1]


class InstallFixture:
    def __init__(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.home = self.root / "home"
        self.dotfiles = self.root / "dotfiles"
        self.module = self.dotfiles / "modules/credproxy"
        self.fake_bin = self.root / "fake-bin"
        self.home.mkdir()
        self.fake_bin.mkdir()
        shutil.copytree(MODULE, self.module)
        (self.dotfiles / "modules/_lib").mkdir(parents=True)
        (self.dotfiles / "modules/_lib/common.sh").write_text(
            'has_cmd() { command -v "$1" >/dev/null 2>&1; }\n'
            'is_linux() { return 1; }\nis_wsl() { return 1; }\n'
            'log() { printf "%s\\n" "$*" >&2; }\n', encoding="utf-8")
        (self.root / "credproxy/cmd/credproxyd").mkdir(parents=True)
        (self.root / "credproxy/cmd/credproxy").mkdir(parents=True)
        (self.root / "credproxy/.git").mkdir()
        go = self.fake_bin / "go"
        go.write_text(
            '#!/bin/sh\nout=""\nwhile [ "$#" -gt 0 ]; do [ "$1" = -o ] && { shift; out="$1"; }; shift; done\n'
            'printf "#!/bin/sh\\nexit 0\\n" > "$out"\nchmod 0755 "$out"\n', encoding="utf-8")
        go.chmod(0o755)
        ctx = self.home / ".local/bin/ctx"
        ctx.parent.mkdir(parents=True)
        ctx.write_text("#!/bin/sh\nexit 0\n", encoding="utf-8")
        ctx.chmod(0o755)

    def close(self): self.temp.cleanup()

    @property
    def config(self): return self.home / ".config/credproxyd/config.toml"

    def run(self):
        env = {"HOME": str(self.home), "DOTFILES_DIR": str(self.dotfiles), "PATH": f"{self.fake_bin}:/usr/bin:/bin", "XDG_CONFIG_HOME": str(self.home / ".config")}
        return subprocess.run(["/usr/bin/env", "bash", str(self.module / "install.sh")], env=env, text=True, capture_output=True)


class InstallManagementTests(unittest.TestCase):
    def setUp(self): self.fixture = InstallFixture()
    def tearDown(self): self.fixture.close()

    def test_fresh_install_copies_all_runtime_identities_and_provenance(self):
        result = self.fixture.run()
        self.assertEqual(result.returncode, 0, result.stderr)
        runtime = self.fixture.home / ".local/lib/credproxy"
        for path in (runtime / "bin/credproxy", runtime / "bin/credproxyd", runtime / "hooks/op-resolve.py"):
            self.assertTrue(path.is_file() and not path.is_symlink(), path)
        self.assertNotIn("@WSL_OP_BIN@", (runtime / "hooks/op-resolve.py").read_text())
        provenance = json.loads(self.fixture.config.with_name("config.toml.managed.json").read_text())
        self.assertEqual(provenance["schema"], "credproxy-managed-config/v1")
        self.assertEqual(provenance["source_revision"], provenance["installed_revision"])
        self.assertFalse((runtime / "bin/ctx-sync").exists())
        self.assertFalse((runtime / "bindings/ctx-sync.json").exists())

    def test_local_config_is_preserved_and_typed_conflicting(self):
        self.fixture.config.parent.mkdir(parents=True)
        self.fixture.config.write_text("# user config\n")
        result = self.fixture.run()
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.fixture.config.read_text(), "# user config\n")
        self.assertIn("conflicting", result.stderr)

    def test_exact_rendered_bytes_without_provenance_are_not_adopted(self):
        first = self.fixture.run()
        self.assertEqual(first.returncode, 0, first.stderr)
        provenance = self.fixture.config.with_name("config.toml.managed.json")
        provenance.unlink()
        before = self.fixture.config.read_bytes()
        second = self.fixture.run()
        self.assertEqual(second.returncode, 2)
        self.assertEqual(self.fixture.config.read_bytes(), before)
        self.assertIn("provenance absent/invalid", second.stderr)

    def test_install_has_no_dependency_on_unreachable_delivery_revision(self):
        text = (MODULE / "install.sh").read_text()
        self.assertNotIn("f46bface", text)

    def test_missing_source_fetches_exact_reviewed_commit_at_depth_one(self):
        shutil.rmtree(self.fixture.root / "credproxy")
        calls = self.fixture.root / "git-calls"
        git = self.fixture.fake_bin / "git"
        git.write_text(
            '#!/bin/sh\n'
            f'printf "%s\\n" "$*" >>"{calls}"\n'
            'if [ "$1" = -C ] && [ "$3" = init ]; then mkdir -p "$2/.git"; exit 0; fi\n'
            'if [ "$1" = -C ] && [ "$3" = remote ]; then exit 0; fi\n'
            'if [ "$1" = -C ] && [ "$3" = fetch ]; then exit 0; fi\n'
            'if [ "$1" = -C ] && [ "$3" = rev-parse ]; then\n'
            '  printf "%s\\n" e366cfbab138a8bac0d98b4764b6bbfd8271f851\n'
            '  exit 0\n'
            'fi\n'
            'if [ "$1" = -c ] && [ "$5" = checkout ]; then\n'
            '  mkdir -p "$4/cmd/credproxyd" "$4/cmd/credproxy"\n'
            '  exit 0\n'
            'fi\n'
            'exit 1\n',
            encoding="utf-8",
        )
        git.chmod(0o755)

        result = self.fixture.run()

        self.assertEqual(result.returncode, 0, result.stderr)
        argv = calls.read_text()
        self.assertIn("remote add origin https://github.com/takezoh/credproxy.git", argv)
        self.assertIn("fetch --depth 1 --filter=blob:none origin e366cfbab138a8bac0d98b4764b6bbfd8271f851", argv)
        self.assertIn("rev-parse FETCH_HEAD", argv)
        self.assertIn("core.hooksPath=/dev/null", argv)
        self.assertIn("checkout --detach e366cfbab138a8bac0d98b4764b6bbfd8271f851", argv)

    def test_incomplete_existing_source_is_conflicting_and_not_replaced(self):
        incomplete = self.fixture.root / "credproxy/cmd/credproxy"
        incomplete.rmdir()

        result = self.fixture.run()

        self.assertEqual(result.returncode, 2)
        self.assertIn("source repository incomplete", result.stderr)
        self.assertFalse(incomplete.exists())

    def test_exact_original_managed_config_is_migrated(self):
        legacy = subprocess.run(
            ["git", "-C", str(REPO), "show", "c4680b140fd5319b5ea4f276825f430834b32783:modules/credproxy/assets/config.toml"],
            check=True, capture_output=True,
        ).stdout
        self.fixture.config.parent.mkdir(parents=True)
        self.fixture.config.write_bytes(legacy)
        result = self.fixture.run()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotEqual(self.fixture.config.read_bytes(), legacy)
        self.assertIn("migrated exact known managed", result.stderr)

    def test_exact_unmodified_managed_config_is_upgraded(self):
        first = self.fixture.run()
        self.assertEqual(first.returncode, 0, first.stderr)
        before = self.fixture.config.read_bytes()
        template = self.fixture.module / "assets/config.toml"
        template.write_text(template.read_text() + "\n# fixture revision\n")
        second = self.fixture.run()
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertNotEqual(self.fixture.config.read_bytes(), before)
        self.assertIn("upgraded exact unmodified managed", second.stderr)


if __name__ == "__main__": unittest.main()
