export PAGER="less"
export LESS="-MNRq"
export LESSOPEN="| src-hilite-lesspipe.sh %s"
export LESSCHARSET="utf-8"
if type lv > /dev/null 2>&1; then
	export LV="-c -la -Ou8"
fi
alias lv="less"
