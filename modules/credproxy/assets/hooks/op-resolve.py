#!/usr/bin/env python3
"""Resolve fixed credproxyd routes from the protected local credential boundary.

Linux/WSL reads the one-time provisioned service-account token only from the
protected ``$HOME/.secrets/op/service-account.token`` boundary. macOS reads one
fixed login-Keychain item with the platform ``security`` binary. There is no
request-selected source or parent-environment token fallback.
"""
from __future__ import annotations

import json
import os
import platform
import stat
import subprocess
import sys
from pathlib import Path
from typing import Callable, Mapping, NoReturn, Sequence


ROUTE_HEADERS = {
	"v1/sync/remote": {
		"Authorization": ("Bearer ", "op://local-dev/Context Fabric/Service Principal/token"),
	},
	"thirdverse-amsterdam-jenkins": {
		"Authorization": ("Bearer ", "op://local-dev/Amsterdam/Jenkins/token"),
	},
}

EXPIRES_IN_SEC = 3600
OP_TIMEOUT_SEC = 25
OP_BIN = "/usr/local/bin/op"
SECURITY_BIN = "/usr/bin/security"
TOKEN_RELATIVE_PATH = Path(".secrets/op/service-account.token")
KEYCHAIN_SERVICE = "com.takezoh.credproxy.op-service-account"
KEYCHAIN_ACCOUNT = "credproxyd"


def fail(reason: str) -> NoReturn:
	sys.stderr.write(f"reason:{reason}\n")
	raise SystemExit(1)


def _protected_token_path(environ: Mapping[str, str]) -> Path:
	home = environ.get("HOME", "")
	if not home:
		fail("credential_source_unavailable")
	root = Path(home)
	if not root.is_absolute() or ".." in root.parts:
		fail("credential_source_unavailable")
	return root / TOKEN_RELATIVE_PATH


def _linux_token(environ: Mapping[str, str], read_bytes: Callable[[Path], bytes]) -> str:
	path = _protected_token_path(environ)
	try:
		for directory in (path.parent.parent, path.parent):
			directory_metadata = directory.lstat()
			if not stat.S_ISDIR(directory_metadata.st_mode) \
				or directory_metadata.st_uid != os.getuid() \
				or stat.S_IMODE(directory_metadata.st_mode) != 0o700:
				fail("credential_source_unavailable")
		metadata = path.lstat()
		if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != os.getuid() \
			or stat.S_IMODE(metadata.st_mode) != 0o600:
			fail("credential_source_unavailable")
		raw = read_bytes(path)
	except (OSError, ValueError):
		fail("credential_source_unavailable")
	try:
		token = raw.decode("utf-8").strip()
	except UnicodeDecodeError:
		fail("credential_source_unavailable")
	if not token:
		fail("credential_source_unavailable")
	return token


def _macos_token(run: Callable[..., subprocess.CompletedProcess[str]]) -> str:
	try:
		proc = run(
			[SECURITY_BIN, "find-generic-password", "-s", KEYCHAIN_SERVICE, "-a", KEYCHAIN_ACCOUNT, "-w"],
			capture_output=True,
			text=True,
			timeout=5,
			env={"PATH": "/usr/bin:/bin", "LANG": "C"},
		)
	except (FileNotFoundError, subprocess.TimeoutExpired):
		fail("credential_source_unavailable")
	if proc.returncode != 0 or not proc.stdout.strip():
		fail("credential_source_unavailable")
	return proc.stdout.strip()


def authority_token(
	platform_name: str,
	environ: Mapping[str, str],
	*,
	read_bytes: Callable[[Path], bytes] = Path.read_bytes,
	run_security: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> str:
	if platform_name == "darwin":
		return _macos_token(run_security)
	if platform_name == "linux":
		return _linux_token(environ, read_bytes)
	fail("credential_source_unavailable")


def op_read(
	ref: str,
	token: str,
	*,
	run: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
	home: str | None = None,
) -> str:
	child_env = {
		"HOME": home or str(Path.home()),
		"LANG": "C.UTF-8",
		"OP_SERVICE_ACCOUNT_TOKEN": token,
	}
	try:
		proc = run(
			[OP_BIN, "read", "--no-newline", ref],
			capture_output=True,
			text=True,
			timeout=OP_TIMEOUT_SEC,
			env=child_env,
		)
	except (FileNotFoundError, subprocess.TimeoutExpired):
		fail("op_unreachable")
	if proc.returncode != 0:
		stderr = (proc.stderr or "").lower()
		if "rate" in stderr and "limit" in stderr:
			fail("op_rate_limited")
		if "vault" in stderr or any(marker in stderr for marker in (
			"isn't a vault", "not found", "no item", "not authorized",
			"permission denied", "forbidden", "does not have access",
		)):
			fail("vault_denied")
		if "service account" in stderr or any(marker in stderr for marker in (
			"invalid service account token", "authentication", "unauthorized",
			"sign in", "signin",
		)):
			fail("credential_source_unavailable")
		fail("op_unreachable")
	return proc.stdout


def resolve_request(
	req: Mapping[str, object],
	*,
	platform_name: str,
	environ: Mapping[str, str],
	read_bytes: Callable[[Path], bytes] = Path.read_bytes,
	run_security: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
	run_op: Callable[..., subprocess.CompletedProcess[str]] = subprocess.run,
) -> dict[str, object]:
	route = req.get("route", "")
	mapping = ROUTE_HEADERS.get(route) if isinstance(route, str) else None
	if mapping is None:
		fail("unknown_route")
	token = authority_token(
		platform_name,
		environ,
		read_bytes=read_bytes,
		run_security=run_security,
	)
	headers = {name: prefix + op_read(ref, token, run=run_op) for name, (prefix, ref) in mapping.items()}
	return {"headers": headers, "expires_in_sec": EXPIRES_IN_SEC}


def main() -> None:
	if sys.argv[1:]:
		fail("bad_request")
	try:
		req = json.load(sys.stdin)
	except (json.JSONDecodeError, ValueError):
		fail("bad_request")
	result = resolve_request(req, platform_name=platform.system().lower(), environ=os.environ)
	json.dump(result, sys.stdout)


if __name__ == "__main__":
	main()
