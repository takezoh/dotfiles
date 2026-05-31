#!/usr/bin/env bash
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

# 行数チェック
LINES=$(wc -l < "$FILE")
if (( LINES > 500 )); then
	echo "[Hook] $FILE is $LINES lines (>500). Consider splitting." >&2
fi

# 隠し Unicode 文字の検出（ゼロ幅スペース、方向制御文字等）
if grep -Pq '[\x{200B}\x{200C}\x{200D}\x{2060}\x{FEFF}\x{202A}-\x{202E}]' "$FILE" 2>/dev/null; then
	echo "[Hook] $FILE contains hidden Unicode characters. Possible injection." >&2
fi

# デバッグステートメントの検出（ソースコードのみ）
case "$FILE" in
	*.ts|*.tsx|*.js|*.jsx)
		if grep -nP '^\s*console\.(log|debug)\(' "$FILE" | head -3 | grep -q .; then
			echo "[Hook] $FILE contains console.log/debug statements." >&2
		fi
		;;
	*.py)
		if grep -nP '^\s*(print\(|breakpoint\(\)|import pdb)' "$FILE" | head -3 | grep -q .; then
			echo "[Hook] $FILE contains print/breakpoint/pdb statements." >&2
		fi
		;;
esac
