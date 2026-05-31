#!/bin/sh
# shellcheck shell=sh
# mise activation (POSIX — detects running shell)

if ! command -v mise >/dev/null 2>&1; then
	return 0 2>/dev/null || true
fi

case "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}" in
	zsh)  eval "$(mise activate zsh)"  ;;
	bash) eval "$(mise activate bash)" ;;
esac
