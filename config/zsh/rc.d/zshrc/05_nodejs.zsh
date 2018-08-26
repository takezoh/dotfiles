if type nodenv >/dev/null 2>&1; then
	alias ndenv='nodenv'
	_nodenv_init() {
		if type brew >/dev/null 2>&1; then
			export NODENV_ROOT=`brew --prefix nodenv`
		else
			export NODENV_ROOT=`cd $HOME/.local/env/nodenv && pwd -P`
		fi

		eval "$(nodenv init -)"
	}
	eval "$(lazyenv.load _nodenv_init nodenv `lazyenv.load.shims ~/.local/env/nodenv/shims`)"
fi
