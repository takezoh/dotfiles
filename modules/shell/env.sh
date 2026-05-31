#!/bin/sh
# shellcheck shell=sh
# Shell tool activation: starship, atuin, zoxide, fzf (POSIX)

command -v starship >/dev/null 2>&1 && eval "$(starship init "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}")"
command -v atuin    >/dev/null 2>&1 && eval "$(atuin init    "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}" --disable-up-arrow)"
command -v zoxide   >/dev/null 2>&1 && eval "$(zoxide init   "${ZSH_VERSION:+zsh}${BASH_VERSION:+bash}")"

if command -v fzf >/dev/null 2>&1; then
	if [ -n "${ZSH_VERSION-}" ]; then
		source <(fzf --zsh)
	elif [ -n "${BASH_VERSION-}" ]; then
		eval "$(fzf --bash)"
	fi
fi
