export GOPATH=$XDG_DATA_HOME/go

if type goenv >/dev/null 2>&1; then

	_golang_init() {
		if type brew >/dev/null 2>&1; then
			export GOENV_ROOT=`brew --prefix goenv`
		else
			export GOENV_ROOT=`cd $HOME/.local/env/goenv && pwd -P`
		fi
		eval "$(goenv init -)"
	}

	eval "$(lazyenv.load _golang_init goenv go gofmt)"
fi
