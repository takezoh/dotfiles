#!/usr/bin/python3
"""Classify Anthropic delivery from executable broker/client observations."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import signal
import socket
import subprocess
import tempfile
import time
import unittest
import uuid
from pathlib import Path

SCHEMA = "credproxy/anthropic-delivery/v1"
CASES = (
    "peer_bound_installed_client", "generic_bearer_rejected", "same_uid_only_rejected",
    "fixed_post_messages", "broker_x_api_key_injection", "caller_credential_header_rejected",
    "finite_argv", "stdin_1mib", "sse_order", "single_in_flight", "next_request_cancel",
    "cancel_deadline", "buffer_64kib", "first_byte_60s", "total_300s", "cleanup",
    "no_retry", "canary_non_leak",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def unix_request(path: Path, request: bytes) -> bytes:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        client.settimeout(2)
        client.connect(str(path))
        client.sendall(request)
        chunks = []
        while True:
            chunk = client.recv(8192)
            if not chunk:
                return b"".join(chunks)
            chunks.append(chunk)
    finally:
        client.close()


def observe(credproxyd: Path, client: Path, timeout: int) -> dict[str, object]:
    if not credproxyd.is_file() or not os.access(credproxyd, os.X_OK):
        return {"state": "not_observed", "reason": "credproxyd_unavailable"}
    if not client.is_file() or not os.access(client, os.X_OK):
        return {"state": "not_observed", "reason": "installed_client_unavailable"}
    secret = "opaque-" + uuid.uuid4().hex
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        socket_path = root / "broker.sock"
        config = root / "config.toml"
        config.write_text(f'listen_unix = "{socket_path}"\nlog_level = "info"\n', encoding="utf-8")
        process = subprocess.Popen(
            [str(credproxyd), "--config", str(config)], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, env={"HOME": str(root), "LANG": "C.UTF-8", "PATH": "/usr/bin:/bin"},
        )
        daemon_stdout = daemon_stderr = ""
        response = b""
        client_result = None
        try:
            deadline = time.monotonic() + timeout
            while time.monotonic() < deadline and not socket_path.exists() and process.poll() is None:
                time.sleep(0.02)
            if not socket_path.exists():
                return {"state": "not_observed", "reason": "credproxyd_start_failed"}
            response = unix_request(
                socket_path,
                b"POST /v1/operations/anthropic-messages HTTP/1.1\r\nHost: credproxyd\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}",
            )
            status = response.split(b"\r\n", 1)[0].decode("ascii", errors="replace")
            client_result = subprocess.run(
                [str(client)], capture_output=True, text=True, timeout=timeout,
                env={"HOME": str(root), "PATH": "/usr/bin:/bin", "ANTHROPIC_API_KEY": secret},
            )
        except (OSError, subprocess.SubprocessError):
            pass
        finally:
            process.send_signal(signal.SIGTERM)
            try:
                daemon_stdout, daemon_stderr = process.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                daemon_stdout, daemon_stderr = process.communicate(timeout=3)
        if client_result is None:
            return {"state": "not_observed", "reason": "executable_probe_failed"}
        captures = response.decode(errors="replace") + client_result.stdout + client_result.stderr + daemon_stdout + daemon_stderr
        return {
            "state": "observed", "credproxyd_revision": f"sha256:{sha256(credproxyd)}",
            "client_revision": f"sha256:{sha256(client)}", "anthropic_operation_status": status,
            "client_exit": client_result.returncode,
            "client_category": client_result.stderr.strip(),
            "credential_material_observed": secret in captures,
        }


def report(mode: str, revision: str, observation: dict[str, object], tier1_report: dict | None = None) -> dict[str, object]:
    cases = {name: "not_observed" for name in CASES}
    if mode == "adapter" and (not tier1_report or tier1_report.get("classification") != "unsupported"):
        classification, reason = "inconclusive", "tier1_explicit_unsupported_required"
    elif observation.get("state") != "observed":
        classification, reason = "inconclusive", str(observation.get("reason", "probe_not_observed"))
    elif observation.get("credential_material_observed"):
        classification, reason = "conflicting", "credential_material_in_capture"
        cases["canary_non_leak"] = "fail"
    elif (
        str(observation.get("anthropic_operation_status", "")).startswith("HTTP/1.1 404")
        and observation.get("client_exit") == 69
        and observation.get("client_category") == "minuet_anthropic_unavailable:provider_disabled"
    ):
        classification, reason = "unsupported", "fixed_anthropic_operation_absent_and_client_disabled"
        cases["peer_bound_installed_client"] = "fail"
        cases["fixed_post_messages"] = "fail"
        cases["canary_non_leak"] = "pass"
    else:
        classification, reason = "conflicting", "broker_client_disablement_mismatch"
    return {
        "schema": SCHEMA, "mode": mode, "runner_revision": revision,
        "credproxyd_revision": observation.get("credproxyd_revision", "not_observed"),
        "client_revision": observation.get("client_revision", "not_observed"),
        "classification": classification, "selected_outcome": "provider_disabled" if classification == "unsupported" else "none",
        "reason": reason, "cases": cases,
        "credential_material_observed": bool(observation.get("credential_material_observed", False)),
        "observations": {
            "state": observation.get("state", "not_observed"),
            "anthropic_operation_status": observation.get("anthropic_operation_status", "not_observed"),
            "client_exit": observation.get("client_exit", "not_observed"),
            "client_category": observation.get("client_category", "not_observed"),
        },
    }


class AnthropicProbeTests(unittest.TestCase):
    observed_disabled = {
        "state": "observed", "credproxyd_revision": "sha256:test", "client_revision": "sha256:test",
        "anthropic_operation_status": "HTTP/1.1 404 Not Found", "client_exit": 69,
        "client_category": "minuet_anthropic_unavailable:provider_disabled", "credential_material_observed": False,
    }

    def test_tier1_requires_executable_absence_and_disabled_client(self):
        value = report("tier1", "test", self.observed_disabled)
        self.assertEqual(value["classification"], "unsupported")
        self.assertEqual(value["cases"]["fixed_post_messages"], "fail")

    def test_missing_or_mismatched_observations_are_not_unsupported(self):
        self.assertEqual(report("tier1", "test", {"state": "not_observed"})["classification"], "inconclusive")
        mutated = dict(self.observed_disabled, client_exit=0)
        self.assertEqual(report("tier1", "test", mutated)["classification"], "conflicting")

    def test_adapter_requires_explicit_tier1_unsupported(self):
        self.assertEqual(report("adapter", "test", self.observed_disabled)["classification"], "inconclusive")
        self.assertEqual(report("adapter", "test", self.observed_disabled, {"classification": "unsupported"})["classification"], "unsupported")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("tier1", "adapter"), required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--producer-revision", default="uncommitted")
    parser.add_argument("--tier1-report", type=Path)
    parser.add_argument("--credproxyd", type=Path, default=Path.home() / ".local/lib/credproxy/bin/credproxyd")
    parser.add_argument("--client", type=Path, default=Path.home() / ".local/lib/credproxy/bin/minuet-anthropic")
    parser.add_argument("--case-timeout", type=int, default=10)
    parser.add_argument("--cancel-deadline-ms", type=int, default=1000)
    args = parser.parse_args()
    tier1 = json.loads(args.tier1_report.read_text()) if args.tier1_report else None
    value = report(args.mode, args.producer_revision, observe(args.credproxyd, args.client, args.case_timeout), tier1)
    args.report.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
    raise SystemExit(0 if value["classification"] in {"supported", "unsupported"} else 2)


if __name__ == "__main__":
    main()
