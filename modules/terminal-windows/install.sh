#!/usr/bin/env bash
# Windows 側に CaskaydiaMono Nerd Font を配置 + レジストリ登録
set -euo pipefail
MODULES_DIR="${MODULES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$MODULES_DIR/_lib/common.sh"

is_wsl || { log "terminal-windows: skip (not WSL)"; exit 0; }

log "terminal-windows: install (nerd font)"

# windows_font_dir=$(wslpath -au "$(cmd.exe /d /c 'echo %LOCALAPPDATA%\Microsoft\Windows\Fonts' 2>/dev/null | tr -d '\r')")
# if [ ! -f "$windows_font_dir/CaskaydiaMono-Regular.ttf" ]; then
# 	nf_tmpdir=$(mktemp -d)
# 	curl -sL -o "$nf_tmpdir/CascadiaMono.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"
# 	unzip -o "$nf_tmpdir/CascadiaMono.zip" -d "$nf_tmpdir/CascadiaMono" "*.ttf"
# 	mkdir -p "$windows_font_dir"
# 	cp "$nf_tmpdir/CascadiaMono/"*.ttf "$windows_font_dir/"
# 	for ttf in "$nf_tmpdir/CascadiaMono/"*.ttf; do
# 		filename=$(basename "$ttf")
# 		reg.exe add "HKCU\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
# 			/v "${filename%.ttf} (TrueType)" /t REG_SZ /d "$filename" /f
# 	done
# 	rm -rf "$nf_tmpdir"
# fi
