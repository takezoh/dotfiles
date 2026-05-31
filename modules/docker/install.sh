#!/bin/bash
# modules/docker/install.sh — Docker CE (公式 apt リポジトリ) + group/service
set -euo pipefail
MODULES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
. "$MODULES_DIR/_lib/common.sh"

# Linux 以外はスキップ
if ! is_linux; then
	log "docker: skip (not linux)"
	exit 0
fi

# ディストリ情報を取得（Docker CE の apt は ubuntu/debian 系を想定）
if [ ! -r /etc/os-release ]; then
	log "docker: /etc/os-release が無いため中断"
	exit 1
fi
# shellcheck disable=SC1091
. /etc/os-release

case "${ID:-}" in
	ubuntu) DOCKER_REPO="ubuntu"; FALLBACK_CODENAME="noble" ;;
	debian) DOCKER_REPO="debian"; FALLBACK_CODENAME="bookworm" ;;
	*)
		log "docker: unsupported distro '${ID:-unknown}' (ubuntu/debian のみ対応)"
		exit 1
		;;
esac

# Ubuntu 派生 (Linux Mint 等) では UBUNTU_CODENAME が実コードネーム
CODENAME="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
if [ -z "$CODENAME" ]; then
	log "docker: コードネームを特定できないため中断"
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# 依存パッケージ（冪等: 既存はスキップされる。curl は後段のコードネーム判定にも使う）
log "docker: installing prerequisites"
as_root apt-get update -q
as_root apt-get install -y ca-certificates curl gnupg

# Docker の apt は新しい OS コードネームに遅れて追従する。
# 対象コードネームの配布が無ければ Docker 対応済みの最新安定版にフォールバックする。
if ! curl -fsS -o /dev/null "https://download.docker.com/linux/${DOCKER_REPO}/dists/${CODENAME}/Release" 2>/dev/null; then
	log "docker: '${CODENAME}' は Docker リポジトリ未対応のため '${FALLBACK_CODENAME}' にフォールバック"
	CODENAME="$FALLBACK_CODENAME"
fi

# GPG キー登録（冪等: 鍵が無いときだけ取得）
KEYRING=/etc/apt/keyrings/docker.gpg
as_root install -m 0755 -d /etc/apt/keyrings
if [ ! -s "$KEYRING" ]; then
	log "docker: fetching GPG key"
	curl -fsSL "https://download.docker.com/linux/${DOCKER_REPO}/gpg" \
		| as_root gpg --dearmor -o "$KEYRING"
	as_root chmod a+r "$KEYRING"
else
	log "docker: GPG key already present"
fi

# apt リポジトリ登録（冪等: 期待内容で毎回上書き）
ARCH="$(dpkg --print-architecture)"
REPO_LINE="deb [arch=${ARCH} signed-by=${KEYRING}] https://download.docker.com/linux/${DOCKER_REPO} ${CODENAME} stable"
log "docker: writing apt source ($CODENAME)"
printf '%s\n' "$REPO_LINE" | as_root tee /etc/apt/sources.list.d/docker.list >/dev/null

# Docker 本体インストール
log "docker: installing engine"
as_root apt-get update -q
as_root apt-get install -y \
	docker-ce \
	docker-ce-cli \
	containerd.io \
	docker-buildx-plugin \
	docker-compose-plugin

# サービス自動起動（systemd 稼働時のみ。既に有効なら無変更で冪等）
if has_cmd systemctl && [ -d /run/systemd/system ]; then
	log "docker: enabling service"
	as_root systemctl enable --now docker
else
	log "docker: systemd 未稼働のためサービス有効化をスキップ"
fi

# docker グループへ実ユーザーを追加（冪等: 未所属のときだけ）
DOCKER_USER="${SUDO_USER:-$(id -un)}"
if [ "$DOCKER_USER" = "root" ]; then
	log "docker: 対象が root のためグループ追加は不要"
elif id -nG "$DOCKER_USER" | tr ' ' '\n' | grep -qx docker; then
	log "docker: $DOCKER_USER は既に docker グループに所属"
else
	log "docker: adding $DOCKER_USER to docker group"
	as_root usermod -aG docker "$DOCKER_USER"
	log "docker: 反映には再ログイン (または 'newgrp docker') が必要"
fi

log "docker: done"
