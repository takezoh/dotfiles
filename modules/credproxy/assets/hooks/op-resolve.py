#!/usr/bin/env python3
"""Resolve fixed credproxyd routes without persistent plaintext credentials.

Linux/WSL receives the 1Password service-account token from systemd's private
``$CREDENTIALS_DIRECTORY/op-service-account`` runtime file.  macOS reads one
fixed login-Keychain item with the platform ``security`` binary.  There is no
file-store, token-file, environment-token, or request-selected fallback.
"""
from __future__ import annotations

import json
import os
import platform
import subprocess
import sys
from pathlib import Path
from typing import Callable, Mapping, NoReturn, Sequence


ROUTE_HEADERS = {
	"v1/sync/remote": {
		"Authorization": ("Bearer ", "op://local-dev/Context Fabric/Service Principal/token"),
	},
}

EXPIRES_IN_SEC = 3600
OP_BIN = "/usr/local/bin/op"
SECURITY_BIN = "/usr/bin/security"
SYSTEMD_CREDENTIAL_NAME = "op-service-account"
KEYCHAIN_SERVICE = "com.takezoh.credproxy.op-service-account"
KEYCHAIN_ACCOUNT = "credproxyd"


def fail(reason: str) -> NoReturn:
	sys.stderr.write(f"reason:{reason}\n")
	raise SystemExit(1)


def _runtime_credential_path(environ: Mapping[str, str]) -> Path:
	directory = environ.get("CREDENTIALS_DIRECTORY", "")
	if not directory:
		fail("credential_source_unavailable")
	root = Path(directory)
	if not root.is_absolute() or ".." in root.parts:
		fail("credential_source_unavailable")
	return root / SYSTEMD_CREDENTIAL_NAME


def _linux_token(environ: Mapping[str, str], read_bytes: Callable[[Path], bytes]) -> str:
	try:
		raw = read_bytes(_runtime_credential_path(environ))
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
			timeout=8,
			env=child_env,
		)
	except (FileNotFoundError, subprocess.TimeoutExpired):
		fail("op_unreachable")
	if proc.returncode != 0:
		stderr = (proc.stderr or "").lower()
		if "rate" in stderr and "limit" in stderr:
			fail("op_rate_limited")
		if "isn't a vault" in stderr or "not found" in stderr or "no item" in stderr:
			fail("vault_denied")
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
	try:
		req = json.load(sys.stdin)
	except (json.JSONDecodeError, ValueError):
		fail("bad_request")
	result = resolve_request(req, platform_name=platform.system().lower(), environ=os.environ)
	json.dump(result, sys.stdout)


if __name__ == "__main__":
	main()
