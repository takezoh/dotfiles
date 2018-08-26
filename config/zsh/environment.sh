# XDG Base Directory Specification  [https://specifications.freedesktop.org/basedir-spec/latest/ar01s03.html]
[[ -z "$XDG_DATA_HOME" ]] && export XDG_DATA_HOME=$HOME/.local/share
[[ -z "$XDG_CONFIG_HOME" ]] && export XDG_CONFIG_HOME=$HOME/.config
[[ -z "$XDG_CACHE_HOME" ]] && export XDG_CACHE_HOME=$HOME/.cache
# export XDG_DATA_DIRS=
# export XDG_CONFIG_DIRS=
# export XDG_RUNTIME_DIR=

typeset -xa _platforms
case "$OSTYPE" in
cygwin)
	_platforms=("cygwin" "windows")
	;;
darwin*)
	_platforms=("darwin" "freebsd")
	;;
linux*)
	if [ -d /mnt/c/Windows ]; then
		_platforms=("wsl" "linux" "windows")
	else
		_platforms=("linux")
	fi
	;;
freebsd*)
	_platforms=("freebsd")
	;;
esac
