#!/usr/bin/env bash
# Windows notification hook - delegates to generic notification script
#

INPUT=$(cat)
HOOK_EVENT=$(printf '%s' "$INPUT" | jq -r '.hook_event_name // empty')
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty')
SCRIPT_PATH="${HOME}/.dotfiles/scripts/notify-windows.sh"

[[ ! -x "$SCRIPT_PATH" ]] && exit 0

case "$HOOK_EVENT" in
	PermissionRequest)
		TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // "unknown"')
		TOOL_INPUT=$(printf '%s' "$INPUT" | jq -r '.tool_input | to_entries[] | "\(.key)=\(.value)" | select(. != "")' | paste -sd ',' -)
		TITLE="Claude Permission Request"
		BODY="[$CWD] $TOOL: $TOOL_INPUT"
		;;
	Notification)
		NOTIF_TYPE=$(printf '%s' "$INPUT" | jq -r '.notification_type // empty')
		case "$NOTIF_TYPE" in
			elicitation_dialog)
				TITLE="Claude Question"
				BODY="[$CWD] Claude is asking you a question"
				;;
			*) exit 0 ;;
		esac
		;;
	Stop)
		TITLE="Claude Finished"
		BODY="[$CWD] Task has completed"
		;;
	*)
		exit 0
		;;
esac

bash "$SCRIPT_PATH" "$TITLE" "$BODY" &
exit 0
