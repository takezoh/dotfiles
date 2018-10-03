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

_grep_options=(
	"--binary-files=without-match"
	"--exclude=.tmp"
	"--exclude=.svn"
	"--exclude=.git"
	"--color=auto"
	"--with-filename"
	"--line-number"
)
if type rg > /dev/null 2>&1; then
	alias grep="rg --with-filename --line-number --ignore-case"
elif type ggrep > /dev/null 2>&1; then
	alias ggrep="ggrep ${_grep_options}"
	alias grep="ggrep ${_grep_options}"
else
	alias grep="grep ${_grep_options}"
fi

alias top="htop"
alias tree="tree -C"
alias v="less"

# psg() {
# 	local str=$1
# 	\ps aux | grep "[$str[1]]$str[2,${#str[@]}]"
# }

alias -g L="|& $PAGER"
alias -g G="| grep"
alias -g H="| head"
alias -g T="| tail"
alias -g S="| sed"

alias -g C="| clipboard -i"
alias -g P="clipboard -o"

if (( ${_platforms[(I)windows]} )); then
	alias open="wstart"
	# alias msbuild="MSBuild.exe"

	if [ "$OSTYPE" = "cygwin" ]; then
		# alias wcmd="`echo ${^path}/cmd.exe(N)` /d /c"
		# alias open="cygstart"
		alias sudo=
	else
		# alias wcmd="wsl-cmdtool wcmd"
		# alias open="wsl-cmdtool wstart"
	fi
fi

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
