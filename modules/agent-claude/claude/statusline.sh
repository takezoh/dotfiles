#!/bin/bash

json=$(cat 2>/dev/null)
if [[ -z "$json" ]]; then
	echo "Error: No JSON input"
	exit 1
fi

eval "$(echo "$json" | jq -r '
	(.model | if type == "object" then .id else . end // "unknown"
		| sub(".*claude-"; "") | sub("-[0-9]+$"; "")) as $m |
	"model_short=\($m)
	context_used=\(.context_window.used_percentage // 0 | floor)
	input_tokens=\(.context_window.total_input_tokens // 0)
	output_tokens=\(.context_window.total_output_tokens // 0)
	total_cost=\(.cost.total_cost_usd // 0)
	effort=\(.effort.level // "medium")"
')"

branch=$(git branch --show-current 2>/dev/null)
dir="${PWD/#$HOME/\~}"

filled=$(( context_used / 10 ))
_f="██████████" _e="░░░░░░░░░░"
context_bar="${_f:0:filled}${_e:0:10-filled}"

printf "%s[%s] | ctx:%d%% %s | \$%.4f | %d↓ %d↑\n" \
	"$model_short" "$effort" "$context_used" "$context_bar" \
	"$total_cost" "$input_tokens" "$output_tokens"

if [[ -n "$branch" ]]; then
	printf "%s | %s\n" "$dir" "$branch"
else
	printf "%s\n" "$dir"
fi
