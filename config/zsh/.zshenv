# zmodload zsh/zprof && zprof

source $HOME/.config/zsh/environment.sh

export ZDOTDIR=$XDG_CONFIG_HOME/zsh/
export ZDOTEXTERNALDIR=$(cd $ZDOTDIR && pwd -P)/../../external

umask 022

# $PATH
typeset -xU PATH path
path=(
	# system
	/usr/local/bin(N-/)
	/home/linuxbrew/.linuxbrew/bin(N-/)
	/usr/bin(N-/)
	/bin(N-/)
	$path
)

# $SUDO
typeset -xTU SUDO_PATH sudo_path
sudo_path=(
	/usr/pkg/sbin(N-/)
	/usr/local/sbin(N-/)
	/home/linuxbrew/.linuxbrew/sbin(N-/)
	/usr/sbin(N-/)
	/sbin(N-/)
	$sudo_path
)

# $MANPATH
typeset -xU MANPATH _manpath
_manpath=(
	/home/linuxbrew/.linuxbrew/share/man(N-/)
	$manpath
)

# $INFOPATH
typeset -xU INFOPATH _infopath
_infopath=(
	/home/linuxbrew/.linuxbrew/share/info(N-/)
	$infopath
)

case "$OSTYPE" in
freebsd*|darwin*|cygwin)
	path=($path $sudo_path) ;;
esac

_zsh.load() {
	for src in `/bin/ls -d $ZDOTDIR/rc.d/$1/*`; do
		source $src
	done
	if [ -n "$_platforms" ]; then
		for platform in $_platforms; do
			if [ -d $ZDOTDIR/rc.d/$1/$platform ]; then
				for src in `/bin/ls -d $ZDOTDIR/rc.d/$1/$platform/*`; do
					source $src
				done
			fi
		done
	fi
	# load .*.local if exists
	local localsrc=$HOME/.local/config/${1}
	[ -f $localsrc ] && source $localsrc
}
