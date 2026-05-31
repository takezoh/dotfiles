#!/usr/bin/env bash
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0

case "$FILE" in
	*.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html|*.yaml|*.yml)
		npx prettier --write "$FILE" >/dev/null 2>&1 ;;
	*.rs)
		rustfmt "$FILE" 2>/dev/null ;;
esac
exit 0
