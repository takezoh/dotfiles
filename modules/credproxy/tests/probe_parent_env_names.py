#!/usr/bin/python3
"""Report only credential-name presence booleans from the current parent env."""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

DEFAULT_NAMES = ("CTX_DATABASE_URL", "XAI_API_KEY", "ANTHROPIC_API_KEY")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", action="append", dest="names", default=[])
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    names = tuple(args.names) or DEFAULT_NAMES
    if any(not name or not name.replace("_", "").isalnum() or name.upper() != name for name in names):
        parser.error("--name must be an uppercase environment name")
    report = {name: name in os.environ for name in sorted(set(names))}
    encoded = json.dumps(report, sort_keys=True) + "\n"
    if args.report:
        args.report.write_text(encoded, encoding="utf-8")
    else:
        sys.stdout.write(encoded)


if __name__ == "__main__": main()
