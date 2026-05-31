#!/bin/sh
# shellcheck shell=sh
# Rust / cargo environment (POSIX-compatible)

if [ -f "$HOME/.cargo/env" ]; then
	. "$HOME/.cargo/env"
fi
