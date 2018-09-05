# zmodload zsh/zprof && zprof

source $HOME/.config/zsh/environment.sh

export ZDOTDIR=$XDG_CONFIG_HOME/zsh/
export DOTDIR=$(cd `readlink -f $ZDOTDIR`/../.. && pwd -P)

umask 022

# $PATH
typeset -xU PATH path
path=(
	# /mnt/c/Program\ Files\ \(x86\)/MSBuild/*/Bin(N-/)
	# /mnt/c/Program\ Files\ \(x86\)/MSBuild/14.0/Bin(N-/)
	# /mnt/c/Program\ Files\ \(x86\)/MSBuild/12.0/Bin(N-/)
	/mnt/c/Program\ Files\ \(x86\)/Microsoft\ Visual\ Studio/2017/Professional/MSBuild/15.0/Bin(N-/)
	# debian gnu
	/var/lib/gems/*/bin(N-/)
	# system
	/usr/local/bin(N-/)
	/usr/bin(N-/)
	/bin(N-/)
	$path
)

# $SUDO
typeset -xTU SUDO_PATH sudo_path
sudo_path=({,/usr/pkg,/usr/local,/usr}/sbin(N-/) $sudo_path)

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
