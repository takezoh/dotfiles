_USER_PYENV_SYSPY=`where python | head -n 1`

if type pyenv >/dev/null 2>&1; then

	_pyenv_init() {
		if type brew >/dev/null 2>&1; then
			export PYENV_ROOT=`brew --prefix pyenv`
		else
			export PYENV_ROOT=$(cd $(dirname $(readlink -f `where pyenv`))/.. && pwd -P)
		fi

		eval "$(pyenv init -)"

		# fixed build problem (https://github.com/pyenv/pyenv/wiki/Common-build-problems)
		# if type brew >/dev/null 2>&1; then
			# local _openssl_prefix=$(brew --prefix openssl)
			# alias pyenv="CFLAGS=\"-I${_openssl_prefix}/include\" LDFLAGS=\"-L${_openssl_prefix}/lib\" pyenv"
		# fi
	}

	eval "$(lazyenv.load _pyenv_init pyenv python pip)"
fi
