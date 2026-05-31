#!/bin/sh
# shellcheck shell=sh
# Bootstrap: repo-root resolution, XDG basedir, platform helpers.
# Sourced by .zshenv, dotfiles.sh, install.sh, profiles/_run.sh, and common.sh.
# Safe to source multiple times (DOTFILES_DIR guards re-execution).

if [ -z "${DOTFILES_DIR-}" ]; then
	if [ -n "${BASH_SOURCE-}" ]; then
		_bs_self="${BASH_SOURCE[0]}"
	elif [ -n "${ZSH_VERSION-}" ]; then
		# shellcheck disable=SC2296
		_bs_self="${(%):-%x}"
	else
		_bs_self="$0"
	fi
	DOTFILES_DIR=$(cd "$(dirname "$_bs_self")/../.." && pwd -P)
	export DOTFILES_DIR
	unset _bs_self
fi

export DOTFILES_MODULES_DIR="$DOTFILES_DIR/modules"
export DOTFILES_EXTERNAL_DIR="$DOTFILES_DIR/external"

# XDG Base Directory Specification
[ -z "${XDG_DATA_HOME-}" ]   && export XDG_DATA_HOME="$HOME/.local/share"
[ -z "${XDG_CONFIG_HOME-}" ] && export XDG_CONFIG_HOME="$HOME/.config"
[ -z "${XDG_CACHE_HOME-}" ]  && export XDG_CACHE_HOME="$HOME/.cache"

# Platform predicates
has_cmd()       { command -v "$1" >/dev/null 2>&1; }
is_wsl()        { [ -d /mnt/c/Windows ]; }
is_darwin()     { [ "$(uname -s)" = "Darwin" ]; }
is_linux()      { [ "$(uname -s)" = "Linux" ]; }
is_devcontainer(){ [ "${DEVCONTAINER:-}" = "1" ]; }

# Default profile name for this host (override with DOTFILES_PROFILE).
#   darwin           -> host-darwin
#   linux + WSL      -> host-wsl
#   linux (headless) -> host-ubuntu-server
dotfiles_profile() {
	if [ -n "${DOTFILES_PROFILE:-}" ]; then
		printf '%s\n' "$DOTFILES_PROFILE"
	elif is_darwin; then
		printf '%s\n' "host-darwin"
	elif is_wsl; then
		printf '%s\n' "host-wsl"
	else
		printf '%s\n' "host-ubuntu-server"
	fi
}

log() { printf '\033[1;34m[module]\033[0m %s\n' "$*" >&2; }

if [ "$(id -u)" = "0" ]; then
	as_root() { "$@"; }
else
	as_root() { sudo "$@"; }
fi

brew_cmd() {
	if [ -x /home/linuxbrew/.linuxbrew/bin/brew ]; then
		/home/linuxbrew/.linuxbrew/bin/brew "$@"
	elif [ -x /opt/homebrew/bin/brew ]; then
		/opt/homebrew/bin/brew "$@"
	else
		brew "$@"
	fi
}

brew_install() {
	for pkg in "$@"; do
		brew_cmd list "$pkg" >/dev/null 2>&1 || brew_cmd install "$pkg"
	done
}

# link <src-relative-to-modules-dir> <dest>
# Uses MODULES_DIR if set (module scripts), otherwise falls back to DOTFILES_MODULES_DIR.
link() {
	(
		_link_src="${MODULES_DIR:-$DOTFILES_MODULES_DIR}/$1"
		_link_dest="$2"
		mkdir -p "$(dirname "$_link_dest")"
		ln -snf "$_link_src" "$_link_dest"
		log "linked: $_link_dest -> $_link_src"
	)
}
