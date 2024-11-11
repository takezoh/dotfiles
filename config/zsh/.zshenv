# zmodload zsh/zprof && zprof

source $HOME/.config/zsh/environment.sh

export ZDOTDIR=$XDG_CONFIG_HOME/zsh/
export ZDOTEXTERNALDIR=$(cd $ZDOTDIR && pwd -P)/../../external

umask 022

if [ -d /home/linuxbrew/.linuxbrew ]; then
	# if [ ! -f $HOME/.cache/linuxbrew/shellenv ]; then
	# 	mkdir -p $HOME/.cache/linuxbrew
	# 	/home/linuxbrew/.linuxbrew/bin/brew shellenv > $HOME/.cache/linuxbrew/shellenv
	# fi
	# source $HOME/.cache/linuxbrew/shellenv
	export HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
	export HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar
	export HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew
fi

# $PATH
typeset -xU PATH path
path=(
	# system
	/home/linuxbrew/.linuxbrew/bin(N-/)
	/opt/homebrew/bin(N-/)
	/usr/local/bin(N-/)
	/usr/bin(N-/)
	/bin(N-/)
	$LOCALAPPDATA/WSL.local/bin(N-/)
	$path
)

# $SUDO
typeset -xTU SUDO_PATH sudo_path
sudo_path=(
	/home/linuxbrew/.linuxbrew/sbin(N-/)
	# /usr/pkg/sbin(N-/)
	/usr/local/sbin(N-/)
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
	if [ -d $HOME/.local/config/$1 ]; then
		for src in `/bin/ls -d $HOME/.local/config/$1/*`; do
			source $src
		done
	fi
}
