autoload -Uz add-zsh-hook

function _osc133_preexec() {
	print -rn -- $'\e]133;C\a'
}

function _osc133_precmd() {
	local exit_code=$?
	print -rn -- $'\e]133;D;'${exit_code}$'\a'
}

add-zsh-hook preexec _osc133_preexec
add-zsh-hook precmd _osc133_precmd
