#!/usr/bin/env bash
# Trust mise.toml in the current workdir so `mise exec` works without prompts.
command -v mise >/dev/null 2>&1 || exit 0
mise trust --quiet 2>/dev/null || true
