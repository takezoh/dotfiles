source $ZDOTEXTERNALDIR/lazyenv/lazyenv.bash
lazyenv.load.shims() {
	[ -d $1 ] && command ls $1
}

lazyenv.shell.loadstart
_zsh.load zshrc
lazyenv.shell.loadfinish

if (which zprof > /dev/null 2>&1) ;then
  zprof
fi
