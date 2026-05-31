#!/bin/bash
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

GCLOUD_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/google-cloud-sdk"

if [ -x "$GCLOUD_ROOT/bin/gcloud" ]; then
	log "cli-gcloud: already installed at $GCLOUD_ROOT"
	exit 0
fi

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${OS}-${ARCH}" in
	linux-x86_64)  TARBALL="google-cloud-cli-linux-x86_64.tar.gz" ;;
	linux-aarch64) TARBALL="google-cloud-cli-linux-arm.tar.gz" ;;
	darwin-x86_64) TARBALL="google-cloud-cli-darwin-x86_64.tar.gz" ;;
	darwin-arm64)  TARBALL="google-cloud-cli-darwin-arm.tar.gz" ;;
	*) log "cli-gcloud: unsupported platform ${OS}-${ARCH}"; exit 1 ;;
esac

URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/${TARBALL}"
TMPDIR_DL="${TMPDIR:-/tmp}/gcloud-install-$$"
mkdir -p "$TMPDIR_DL"
trap 'rm -rf "$TMPDIR_DL"' EXIT

log "cli-gcloud: downloading $URL"
curl -fsSL "$URL" -o "$TMPDIR_DL/$TARBALL"

log "cli-gcloud: extracting to ${XDG_DATA_HOME:-$HOME/.local/share}"
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}"
tar -xzf "$TMPDIR_DL/$TARBALL" -C "${XDG_DATA_HOME:-$HOME/.local/share}"

log "cli-gcloud: running install.sh"
"$GCLOUD_ROOT/install.sh" \
	--quiet \
	--usage-reporting=false \
	--command-completion=false \
	--path-update=false

log "cli-gcloud: installed at $GCLOUD_ROOT"
