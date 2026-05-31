export PAGER="less"
export LESS="-MNRq"
if type bat > /dev/null 2>&1; then
	export LESSOPEN="| bat --style=plain --color=always --paging=never %s"
fi
export LESSCHARSET="utf-8"
if type lv > /dev/null 2>&1; then
	export LV="-c -la -Ou8"
fi
alias lv="less"
