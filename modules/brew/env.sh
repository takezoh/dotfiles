#!/bin/sh
# shellcheck shell=sh
# Homebrew / Linuxbrew environment (POSIX-compatible)

if [ -d /home/linuxbrew/.linuxbrew ]; then
	HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
	HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar
	HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew
	export HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
	PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"
	export PATH
elif [ -d /opt/homebrew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
fi
