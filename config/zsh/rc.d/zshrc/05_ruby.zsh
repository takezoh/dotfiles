if type rbenv >/dev/null 2>&1; then
	_rbenv_init() {
		if type brew >/dev/null 2>&1; then
			export RBENV_ROOT=`brew --prefix rbenv`
		else
			export RBENV_ROOT=`cd $HOME/.local/env/rbenv && pwd -P`
		fi
		eval "$(rbenv init -)"
	}
	# eval "$(lazyenv.load _rbenv_init rbenv `lazyenv.load.shims ~/.local/env/rbenv/shims`)"
	eval "$(lazyenv.load _rbenv_init rbenv ruby gem bundler bundle)"
fi
