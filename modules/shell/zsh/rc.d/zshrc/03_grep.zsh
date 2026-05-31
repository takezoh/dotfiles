export RIPGREP_CONFIG_PATH=${XDG_CONFIG_HOME}/ripgrep/ripgreprc


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
