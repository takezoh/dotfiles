#!/usr/bin/env bash
[[ -z "$SLACK_WEBHOOK_URL" ]] && exit 0
NOTIFICATION_URL="$SLACK_WEBHOOK_URL"

INPUT=$(cat)
HOOK_EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty')
HOST=$(hostname)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')

case "$HOOK_EVENT" in
	PermissionRequest)
		TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // "unknown"')
		TOOL_INPUT=$(printf '%s' "$INPUT" | jq -r '.tool_input | to_entries[] | "\(.key)=\(.value)" | select(. != "")' | paste -sd ',' -)
		TEXT="[$HOST] [$CWD] Claude requests permission for: $TOOL [$TOOL_INPUT]"
		;;
	Notification)
		NOTIF_TYPE=$(printf '%s' "$INPUT" | jq -r '.notification_type // empty')
		case "$NOTIF_TYPE" in
			elicitation_dialog) TEXT="[$HOST] [$CWD] Claude is asking you a question" ;;
			*) exit 0 ;;
		esac
		;;
	Stop)
		TEXT="[$HOST] [$CWD] Claude has finished"
		;;
	*)
		exit 0
		;;
esac

curl -s -X POST "$NOTIFICATION_URL" \
	-H 'Content-Type: application/json' \
	-d "{\"text\":\"$TEXT\"}" > /dev/null

exit 0
