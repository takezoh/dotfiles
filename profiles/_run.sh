#!/usr/bin/env bash
# profiles/_run.sh — profile runner
#
# Usage (from a profile script):
#   modules=(brew mise shell ...)
#   PHASE=${1:-all}   # install | setup | update | all
#   . "$(dirname "$0")/_run.sh"
#
# For each module in $modules[], runs:
#   - modules/<m>/install.sh  (if PHASE=install or all)
#   - modules/<m>/setup.sh    (if PHASE=setup   or all)
#   - modules/<m>/update.sh   (if PHASE=update  — NOT included in all)
#
# MODULES_DIR is exported so module scripts can call link().

set -euo pipefail

# Locate bootstrap via _run.sh's own path (BASH_SOURCE[0] works even when sourced).
# shellcheck disable=SC1091
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/../modules/_lib/bootstrap.sh"

MODULES_DIR="$DOTFILES_MODULES_DIR"
export MODULES_DIR

PHASE="${PHASE:-${1:-all}}"

# Run a script respecting its shebang (e.g., zsh-required scripts).
# Falls back to bash if no shebang or not executable.
_run_script() {
	if [ -x "$1" ]; then
		"$1"
	else
		bash "$1"
	fi
}

for m in "${modules[@]}"; do
	if [ "$PHASE" = "install" ] || [ "$PHASE" = "all" ]; then
		if [ -f "$MODULES_DIR/$m/install.sh" ]; then
			echo "[profile] install: $m"
			_run_script "$MODULES_DIR/$m/install.sh"
		fi
	fi
	if [ "$PHASE" = "setup" ] || [ "$PHASE" = "all" ]; then
		if [ -f "$MODULES_DIR/$m/setup.sh" ]; then
			echo "[profile] setup: $m"
			_run_script "$MODULES_DIR/$m/setup.sh"
		fi
	fi
	if [ "$PHASE" = "update" ]; then
		if [ -f "$MODULES_DIR/$m/update.sh" ]; then
			echo "[profile] update: $m"
			_run_script "$MODULES_DIR/$m/update.sh"
		fi
	fi
done
