# linuxbrew
if [ -d /home/linuxbrew/.linuxbrew ]; then
	export HOMEBREW_PREFIX=/home/linuxbrew/.linuxbrew
	export HOMEBREW_CELLAR=/home/linuxbrew/.linuxbrew/Cellar
	export HOMEBREW_REPOSITORY=/home/linuxbrew/.linuxbrew/Homebrew
fi

# $PATH (macOS path_helper より後に設定する必要がある)
typeset -xU PATH path
path=(
	# user
	$DOTFILES_DIR/scripts(N-/)
	# system
	$HOME/.local/bin(N-/)
	/home/linuxbrew/.linuxbrew/bin(N-/)
	/opt/homebrew/bin(N-/)
	/usr/local/bin(N-/)
	/usr/bin(N-/)
	/bin(N-/)
	$path
)

if is_wsl; then
	path=(
		$DOTFILES_DIR/scripts/wsl(N-/)
		$path
	)
fi

# $SUDO
typeset -xTU SUDO_PATH sudo_path
sudo_path=(
	/home/linuxbrew/.linuxbrew/sbin(N-/)
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
