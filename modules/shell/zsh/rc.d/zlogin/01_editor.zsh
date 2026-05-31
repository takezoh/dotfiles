# EDITOR
if type nvim >/dev/null 2>&1; then
	export EDITOR=nvim
	alias vim='env LANG=ja_JP.UTF-8 $EDITOR "$@"'
	alias vi='vim'
else
	export EDITOR=vim
	if ! type vim > /dev/null 2>&1; then
		alias vim='vi'
	fi
fi
