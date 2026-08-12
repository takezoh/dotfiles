#!/usr/bin/python3
"""Run the sanitized inventory against an explicitly selected installed root."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from test_credential_inventory import build_inventory


def main() -> None:
	parser = argparse.ArgumentParser()
	parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[3])
	parser.add_argument("--home", type=Path, required=True)
	parser.add_argument("--installed-config", type=Path, required=True)
	parser.add_argument("--report", type=Path, required=True)
	parser.add_argument("--consumer-root", type=Path, action="append", default=[])
	args = parser.parse_args()
	report = build_inventory(args.repo_root, args.home, args.installed_config, tuple(args.consumer_root))
	args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
	if report["closure"]["classification"] != "determinate":
		raise SystemExit(2)


if __name__ == "__main__":
	main()
