import unittest
from pathlib import Path


MODULE = Path(__file__).resolve().parents[1]
REPO_ROOT = MODULE.parents[1]
PROFILES = (
    REPO_ROOT / "profiles/host-wsl.sh",
    REPO_ROOT / "profiles/host-darwin.sh",
    REPO_ROOT / "profiles/host-ubuntu-server.sh",
)


class ContextFabricHandoffTest(unittest.TestCase):
    def test_supported_profiles_have_one_runtime_owner(self):
        for profile in PROFILES:
            source = profile.read_text()
            modules = source[source.index("modules=(") : source.index(")", source.index("modules=("))]
            self.assertRegex(modules, r"(?m)^\s*agent-module\s*$")
            self.assertNotRegex(modules, r"(?m)^\s*context-fabric-service\s*$")
            self.assertRegex(modules, r"(?m)^\s*credproxy\s*$")

    def test_adapter_exports_exact_public_handoff_without_credentials(self):
        source = (MODULE / "context-fabric-handoff.sh").read_text()
        self.assertIn('export CREDPROXY_BROKER_SOCKET="$(broker_socket_path)"', source)
        self.assertIn("export CONTEXT_FABRIC_LEGACY_OWNER_STATE=absent", source)
        for forbidden in ("credential", "token", "principal", "systemd-creds"):
            lines = [line for line in source.splitlines() if not line.lstrip().startswith("#")]
            self.assertNotIn(forbidden, "\n".join(lines).lower())

    def test_every_agent_module_phase_sources_handoff(self):
        needle = '. "$(dirname "$0")/context-fabric-handoff.sh"'
        for phase in ("install.sh", "setup.sh", "update.sh"):
            self.assertIn(needle, (MODULE / phase).read_text())


if __name__ == "__main__":
    unittest.main()
