# zmodload zsh/zprof && zprof

# Resolve bootstrap.sh via this file's real path (symlink-safe).
source "${${(%):-%x}:A:h}/../../_lib/bootstrap.sh"

export ZDOTDIR=$XDG_CONFIG_HOME/zsh/

_zsh.load() {
	for src in $(/bin/ls -d $ZDOTDIR/rc.d/$1/*); do
		source $src
	done
	# load .*.local if exists
	if [ -d $HOME/.local/config/$1 ]; then
		for src in $(/bin/ls -d $HOME/.local/config/$1/*); do
			source $src
		done
	fi
}

_zsh.load zshenv
