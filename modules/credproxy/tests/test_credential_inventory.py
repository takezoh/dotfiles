#!/usr/bin/python3
"""Secret-value-free route/store/profile inventory for credproxy migration."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import stat
import sys
import tempfile
import unittest
from pathlib import Path

try:
	import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python 3.11 is the supported runner
	tomllib = None


SCHEMA = "credproxy-inventory/v1"
ROUTES = {
	"ctx-sync": {
		"credential_names": ["CTX_DATABASE_URL"],
		"delivery_kind": "env-body",
		"owner": "dotfiles:modules/credproxy",
		"consumer": {"identity": "context-fabric:ctx-sync", "revision": "pending-hook-cutover"},
		"disposition": "keep",
	},
	"grok-x-search": {
		"credential_names": ["XAI_API_KEY"],
		"delivery_kind": "env-body",
		"owner": "dotfiles:modules/credproxy",
		"consumer": {"identity": "generic-skills:grok-x-search", "revision": "53e0ae7a447b58e3470e8a1816616864ffb26f65"},
		"disposition": "retired-oauth-only",
	},
	"anthropic": {
		"credential_names": ["ANTHROPIC_API_KEY"],
		"delivery_kind": "fixed-http-capability-disabled",
		"owner": "dotfiles:modules/credproxy",
		"consumer": {"identity": "editor-nvim:minuet", "revision": "minuet-anthropic/1"},
		"disposition": "disabled-caller-admission-unsupported",
	},
}

LEGACY_PATHS = (
	("resolved-store", "~/.secrets/credproxyd/resolved.json", "credential-store", "retire"),
	("service-account-token", "~/.secrets/op/service-account.token", "bootstrap-token", "retire"),
	("broker-token", "~/.config/credproxyd/token", "admission-token", "retire"),
	("grok-script-env", "<installed-grok-x-search>/scripts/.env", "credential-store", "retire"),
	("grok-env-copy", "~/.secrets/env/skills-grok-x-search-scripts", "credential-store", "retire"),
	("anthropic-key", "~/.secrets/anthropic_key", "credential-store", "retire"),
	("source-shell-profile", "modules/credproxy/assets/shellenv/credproxy-env.sh", "profile", "retire"),
	("installed-shell-profile", "~/.local/config/zshrc/50_credproxy-env.zsh", "profile", "retire"),
)


def sha256(path: Path) -> str:
	digest = hashlib.sha256()
	with path.open("rb") as stream:
		for chunk in iter(lambda: stream.read(128 * 1024), b""):
			digest.update(chunk)
	return digest.hexdigest()


def metadata(path: Path) -> dict[str, object]:
	"""Return metadata only. This function intentionally never opens path."""
	try:
		info = path.lstat()
	except FileNotFoundError:
		return {"state": "absent"}
	except OSError:
		return {"state": "inconclusive"}
	kind = "symlink" if stat.S_ISLNK(info.st_mode) else "regular" if stat.S_ISREG(info.st_mode) else "other"
	return {
		"state": "present",
		"kind": kind,
		"mode": format(stat.S_IMODE(info.st_mode), "04o"),
		"uid": info.st_uid,
		"mtime_ns": info.st_mtime_ns,
	}


def installed_grok_env_metadata(home: Path) -> dict[str, object]:
	"""Resolve installed skill copies by path only; never open a matched .env."""
	matches: list[Path] = []
	for root in (home / ".codex/plugins/cache", home / ".claude/plugins/cache"):
		if root.is_dir():
			matches.extend(root.glob("**/skills/grok-x-search/scripts/.env"))
	if not matches:
		return {"state": "absent", "paths": []}
	entries = []
	for path in sorted(set(matches)):
		display = "~/" + str(path.relative_to(home))
		entries.append({"path": display, "metadata": metadata(path)})
	return {"state": "present", "paths": entries}


def config_routes(path: Path) -> tuple[list[str], str]:
	if tomllib is None:
		raise RuntimeError("tomllib_unavailable")
	with path.open("rb") as stream:
		data = tomllib.load(stream)
	routes = []
	for entry in data.get("route", []):
		route_path = entry.get("path")
		if not isinstance(route_path, str) or not route_path.startswith("/"):
			raise ValueError("invalid_route_path")
		routes.append(route_path[1:])
	for entry in data.get("operation", []):
		name = entry.get("name")
		if not isinstance(name, str) or not name:
			raise ValueError("invalid_operation_name")
		routes.append(name)
	return routes, sha256(path)


def managed_config_provenance(path: Path, installed_revision: str, template_revision: str) -> dict[str, object]:
	if not path.is_file() or path.is_symlink():
		return {"classification": "conflicting", "reason": "provenance_absent_or_invalid"}
	try:
		value = json.loads(path.read_text(encoding="utf-8"))
	except (OSError, UnicodeError, json.JSONDecodeError):
		return {"classification": "conflicting", "reason": "provenance_invalid"}
	expected = {
		"schema": "credproxy-managed-config/v1", "owner": "dotfiles:modules/credproxy",
		"source_revision": f"sha256:{installed_revision}",
		"installed_revision": f"sha256:{installed_revision}",
		"template_revision": f"sha256:{template_revision}",
	}
	if value != expected:
		return {"classification": "conflicting", "reason": "provenance_revision_mismatch"}
	return {"classification": "determinate", "reason": None}


def installed_xai_consumer_references(home: Path, extra_roots: tuple[Path, ...] = ()) -> dict[str, object]:
	"""Scan only source/config text for credential-name/path references."""
	roots = (*extra_roots, home / ".codex/plugins/cache", home / ".claude/plugins/cache")
	extensions = {".py", ".sh", ".zsh", ".toml", ".json", ".yaml", ".yml", ".md"}
	matches = []
	for root in roots:
		if not root.is_dir():
			continue
		for path in root.rglob("*"):
			if not path.is_file() or path.is_symlink() or path.name == ".env" or path.suffix not in extensions:
				continue
			try:
				text = path.read_text(encoding="utf-8")
			except (OSError, UnicodeError):
				continue
			if "XAI_API_KEY" in text or 'path = "/grok-x-search"' in text or "/grok-x-search/" in text:
				try:
					display = "~/" + str(path.relative_to(home))
				except ValueError:
					display = str(path)
				matches.append(display)
	return {"classification": "conflicting" if matches else "determinate", "references": sorted(set(matches))}


def build_inventory(repo_root: Path, home: Path, installed_config: Path | None, consumer_roots: tuple[Path, ...] = ()) -> dict[str, object]:
	source_config = repo_root / "modules/credproxy/assets/config.toml"
	source_routes, source_revision = config_routes(source_config)
	installed_state: dict[str, object]
	installed_routes: list[str] = []
	if installed_config is None or not installed_config.exists():
		installed_state = {"state": "absent", "revision": None}
	else:
		installed_routes, installed_revision = config_routes(installed_config)
		provenance_path = installed_config.with_name("config.toml.managed.json")
		provenance = managed_config_provenance(provenance_path, installed_revision, source_revision)
		installed_state = {"state": "present", "revision": f"sha256:{installed_revision}", "provenance": provenance}

	all_routes = sorted(set(source_routes) | set(installed_routes) | set(ROUTES))
	route_items = []
	unknown = []
	conflicts = []
	if installed_state.get("provenance", {}).get("classification") == "conflicting":
		conflicts.append(f"installed-config:{installed_state['provenance']['reason']}")
	for route_id in all_routes:
		declaration = ROUTES.get(route_id)
		if declaration is None:
			unknown.append(f"route:{route_id}")
			route_items.append({"route_id": route_id, "classification": "unknown"})
			continue
		present = {"source": route_id in source_routes, "installed": route_id in installed_routes}
		expected_present = declaration["disposition"] == "keep"
		if present["source"] != expected_present:
			conflicts.append(f"route-source-disposition:{route_id}")
		if installed_state["state"] == "present" and present["installed"] != expected_present:
			conflicts.append(f"route-provenance:{route_id}")
		route_items.append({
			"route_id": route_id,
			**declaration,
			"source_revision": f"sha256:{source_revision}",
			"installed_revision": installed_state["revision"],
			"present": present,
			"classification": "determinate",
		})

	path_items = []
	for item_id, display_path, path_kind, disposition in LEGACY_PATHS:
		if item_id == "grok-script-env":
			observed = installed_grok_env_metadata(home)
		elif display_path.startswith("~/"):
			observed = metadata(home / display_path[2:])
		elif display_path.startswith("modules/"):
			observed = metadata(repo_root / display_path)
		else:
			observed = {"state": "inconclusive"}
		path_items.append({
			"id": item_id,
			"path": display_path,
			"kind": path_kind,
			"owner": "dotfiles:modules/credproxy",
			"disposition": disposition,
			"metadata": observed,
		})
		if observed["state"] == "inconclusive":
			unknown.append(f"path:{item_id}")
	xai_consumers = installed_xai_consumer_references(home, consumer_roots)
	if xai_consumers["classification"] != "determinate":
		conflicts.extend(f"xai-consumer:{path}" for path in xai_consumers["references"])

	classification = "conflicting" if conflicts else "unknown" if unknown else "determinate"
	return {
		"schema": SCHEMA,
		"producer": {
			"repository": "dotfiles",
			"source_revision": f"config-sha256:{source_revision}",
		},
		"inputs": {
			"source_config": "modules/credproxy/assets/config.toml",
			"installed_config": str(installed_config) if installed_config else None,
			"installed": installed_state,
		},
		"routes": route_items,
		"paths": path_items,
		"xai_consumers": xai_consumers,
		"closure": {"classification": classification, "unknown": unknown, "conflicting": conflicts},
	}


class InventoryTests(unittest.TestCase):
	def _provenance(self, source: Path, installed: Path) -> None:
		installed_sha, template_sha = sha256(installed), sha256(source)
		installed.with_name("config.toml.managed.json").write_text(json.dumps({
			"schema": "credproxy-managed-config/v1", "owner": "dotfiles:modules/credproxy",
			"source_revision": f"sha256:{installed_sha}", "installed_revision": f"sha256:{installed_sha}",
			"template_revision": f"sha256:{template_sha}",
		}))
	def _repo(self, root: Path, extra: str = "") -> Path:
		config = root / "modules/credproxy/assets/config.toml"
		config.parent.mkdir(parents=True)
		config.write_text(
			'listen_unix = "/fixed/socket"\n'
			'[[route]]\npath = "/ctx-sync"\n' + extra,
			encoding="utf-8",
		)
		(root / "modules/credproxy/assets/shellenv").mkdir(parents=True)
		(root / "modules/credproxy/assets/shellenv/credproxy-env.sh").touch()
		return root

	def test_metadata_does_not_read_file_content(self) -> None:
		with tempfile.TemporaryDirectory() as temp:
			path = Path(temp) / "secret"
			path.write_bytes(b"NONSECRET_TEST_CANARY")
			observed = metadata(path)
			self.assertEqual(observed["state"], "present")
			self.assertNotIn("NONSECRET_TEST_CANARY", json.dumps(observed))

	def test_complete_matching_inventory_is_determinate(self) -> None:
		with tempfile.TemporaryDirectory() as temp:
			root = self._repo(Path(temp) / "repo")
			home = Path(temp) / "home"
			home.mkdir()
			installed = Path(temp) / "installed.toml"
			installed.write_bytes((root / "modules/credproxy/assets/config.toml").read_bytes())
			self._provenance(root / "modules/credproxy/assets/config.toml", installed)
			result = build_inventory(root, home, installed)
			self.assertEqual(result["closure"]["classification"], "determinate")
			self.assertEqual({item["route_id"] for item in result["routes"]}, set(ROUTES))

	def test_unknown_installed_route_blocks_closure(self) -> None:
		with tempfile.TemporaryDirectory() as temp:
			root = self._repo(Path(temp) / "repo")
			home = Path(temp) / "home"
			home.mkdir()
			installed = Path(temp) / "installed.toml"
			installed.write_text((root / "modules/credproxy/assets/config.toml").read_text() + '[[route]]\npath = "/local-route"\n')
			self._provenance(root / "modules/credproxy/assets/config.toml", installed)
			result = build_inventory(root, home, installed)
			self.assertEqual(result["closure"]["classification"], "unknown")
			self.assertIn("route:local-route", result["closure"]["unknown"])

	def test_matching_bytes_without_provenance_are_conflicting(self) -> None:
		with tempfile.TemporaryDirectory() as temp:
			root = self._repo(Path(temp) / "repo")
			home = Path(temp) / "home"; home.mkdir()
			installed = Path(temp) / "installed.toml"
			installed.write_bytes((root / "modules/credproxy/assets/config.toml").read_bytes())
			result = build_inventory(root, home, installed)
			self.assertEqual(result["closure"]["classification"], "conflicting")
			self.assertIn("installed-config:provenance_absent_or_invalid", result["closure"]["conflicting"])

	def test_another_installed_xai_consumer_is_conflicting(self) -> None:
		with tempfile.TemporaryDirectory() as temp:
			root = self._repo(Path(temp) / "repo")
			home = Path(temp) / "home"
			consumer = home / ".codex/plugins/cache/example/consumer.py"
			consumer.parent.mkdir(parents=True)
			consumer.write_text('name = "XAI_API_KEY"\n', encoding="utf-8")
			result = build_inventory(root, home, None)
			self.assertEqual(result["closure"]["classification"], "conflicting")
			self.assertTrue(result["xai_consumers"]["references"])


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[3])
	parser.add_argument("--home", type=Path, default=Path.home())
	parser.add_argument("--installed-config", type=Path)
	parser.add_argument("--consumer-root", type=Path, action="append", default=[])
	parser.add_argument("--report", type=Path)
	parser.add_argument("--self-test", action="store_true")
	args = parser.parse_args()
	if args.self_test:
		result = unittest.main(argv=[sys.argv[0]], exit=False)
		raise SystemExit(not result.result.wasSuccessful())
	report = build_inventory(args.repo_root, args.home, args.installed_config, tuple(args.consumer_root))
	encoded = json.dumps(report, indent=2, sort_keys=True) + "\n"
	if args.report:
		args.report.write_text(encoded, encoding="utf-8")
	else:
		sys.stdout.write(encoded)
	if report["closure"]["classification"] != "determinate":
		raise SystemExit(2)


if __name__ == "__main__":
	main()
