#!/usr/bin/python3
"""Profile runner failure propagation contract."""
from __future__ import annotations

import subprocess
import shutil
import tempfile
import unittest
from pathlib import Path


RUNNER = Path(__file__).resolve().parents[1] / "_run.sh"


class ProfileRunnerErrorTests(unittest.TestCase):
    def test_child_error_is_preserved_and_annotated_with_phase_and_module(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            modules = root / "modules"
            profiles = root / "profiles"
            module = modules / "failing-module"
            lib = modules / "_lib"
            module.mkdir(parents=True)
            lib.mkdir()
            profiles.mkdir()
            runner = profiles / "_run.sh"
            shutil.copy2(RUNNER, runner)
            (lib / "bootstrap.sh").write_text(
                f'DOTFILES_MODULES_DIR="{modules}"\n', encoding="utf-8"
            )
            install = module / "install.sh"
            install.write_text(
                '#!/usr/bin/env bash\nprintf "native installer detail\\n" >&2\nexit 23\n',
                encoding="utf-8",
            )
            install.chmod(0o755)
            profile = root / "profile.sh"
            profile.write_text(
                '#!/usr/bin/env bash\n'
                'set -euo pipefail\n'
                'modules=(failing-module)\n'
                'PHASE=install\n'
                f'. "{runner}"\n',
                encoding="utf-8",
            )

            result = subprocess.run(
                ["/usr/bin/env", "bash", str(profile)],
                env={"PATH": "/usr/bin:/bin", "HOME": str(root / "home")},
                text=True,
                capture_output=True,
            )

        self.assertEqual(result.returncode, 23)
        self.assertIn("native installer detail", result.stderr)
        self.assertIn("install: failing-module", result.stderr)
        self.assertIn("exit 23", result.stderr)


if __name__ == "__main__":
    unittest.main()
