autoload -Uz add-zsh-hook

NOTIFICATION_THRESHOLD=30

function _notification_preexec() {
	local cmd=(${(z)1})
	case "${cmd[1]}" in
		rs|vim|claude|codex|gemini) ;;
		*)
			NOTIFICATION_START_TIME=$SECONDS
			;;
	esac
}

function _notification_precmd() {
	if [ -n "${NOTIFICATION_START_TIME+x}" ]; then
		local elapsed=$(( SECONDS - NOTIFICATION_START_TIME ))
		if (( elapsed >= NOTIFICATION_THRESHOLD )); then
			$DOTFILES_DIR/scripts/notify-windows.sh "Terminal" "Task completed (${elapsed}s)"
		fi
		unset NOTIFICATION_START_TIME
	fi
}
add-zsh-hook preexec _notification_preexec
add-zsh-hook precmd _notification_precmd

