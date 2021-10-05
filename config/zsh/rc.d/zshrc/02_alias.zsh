## Alias configuration
#
# expand aliases before completing
#
setopt complete_aliases     # aliased ls needs if file/dir completions work

alias sudo="sudo "

alias where="command -v"
alias jobs="jobs -l"

if (( ${_platforms[(I)freebsd]} )); then
	alias ls="ls -G -w -F"
else
	alias ls="ls --color -F"
fi

alias la="ls -a"
alias ll="ls -l"

alias ln="ln -n"

# alias mkdir="mkdir -p"
alias mv="mv -i"

if (( ${_platforms[(I)darwin]} )); then
	alias cp="cp -c"
fi

# alias rm="rm -r"
# alias rr="command rm -rf"

alias du="du -h"
alias df="df -h"

alias su="su -l"

alias pd="popd"

alias diff="diff \
	--ignore-space-change \
	--ignore-tab-expansion \
	--ignore-blank-lines \
	--strip-trailing-cr \
	--suppress-common-lines \
	--recursive"

alias top="htop"
alias tree="tree -C"
# alias v="less"

# psg() {
# 	local str=$1
# 	\ps aux | grep "[$str[1]]$str[2,${#str[@]}]"
# }

alias -g L="|& $PAGER"
alias -g G="| grep"
alias -g H="| head"
alias -g T="| tail"
alias -g S="| sed"
alias -g F="| fzf"

alias -g C="| clipboard -i"
alias -g P="clipboard -o"

# filetype alias
alias -s txt="less"
alias -s readme="less"
# archive
alias -s zip="unzip"
alias -s rar="unrar"
alias -s tar.gz="tar zxf"
alias -s tgz="tar zxf"
alias -s gz="tar zxf"
alias -s tbz="tar jxf"
alias -s bz2="tar jxf"


if (( ${_platforms[(I)windows]} )); then
	if [ "$OSTYPE" = "cygwin" ]; then
		alias sudo=
	fi

	alias cmd="wcmd"
	alias cmd.exe="wcmd"

	alias -s bat="open"
	# alias -s exe="wcmd"
fi

alias -s wav="open"
alias -s wav\"="open"
