#!/bin/sh
# shellcheck shell=sh
# Google Cloud CLI environment (POSIX-compatible)

_gcloud_root="${XDG_DATA_HOME:-$HOME/.local/share}/google-cloud-sdk"

if [ ! -d "$_gcloud_root" ]; then
	unset _gcloud_root
	return 0 2>/dev/null || true
fi

if [ -n "${ZSH_VERSION-}" ]; then
	[ -f "$_gcloud_root/path.zsh.inc" ]       && . "$_gcloud_root/path.zsh.inc"
	[ -f "$_gcloud_root/completion.zsh.inc" ] && . "$_gcloud_root/completion.zsh.inc"
else
	[ -f "$_gcloud_root/path.bash.inc" ]      && . "$_gcloud_root/path.bash.inc"
fi

unset _gcloud_root
