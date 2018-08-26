if type luaenv >/dev/null 2>&1; then
	_luaenv_init() {
		if type brew >/dev/null 2>&1; then
			export LUAENV_ROOT=`brew --prefix luaenv`
		else
			export LUAENV_ROOT=`cd $HOME/.local/env/luaenv && pwd -P`
		fi
		eval "$(luaenv init -)"
	}
	eval "$(lazyenv.load _luaenv_init luaenv `lazyenv.load.shims ~/.local/env/luaenv/shims`)"
fi
