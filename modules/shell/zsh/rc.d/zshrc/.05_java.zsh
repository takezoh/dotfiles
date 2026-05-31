if type jenv >/dev/null 2>&1; then

	_jenv_init() {
		if type brew >/dev/null 2>&1; then
			export JENV_ROOT=`brew --prefix jenv`
		else
			export JENV_ROOT=`cd $HOME/.local/env/jenv && pwd -P`
		fi

		eval "$(jenv init -)"

		(
			cd $JENV_ROOT
			for v in `command ls versions`; do
				unlink versions/$v
			done

			for jroot in /System/Library/Java /Library/Java; do
				for jdk in `[ -d $jroot/JavaVirtualMachines ] && command ls -d $jroot/JavaVirtualMachines/*`; do
					if [ -d $jdk/Contents/Home ]; then
						jenv add $jdk/Contents/Home
					fi
				done
			done
		)

		alias javac='javac -J-Dfile.encoding=UTF-8'
	}
	eval "$(lazyenv.load _jenv_init jenv `lazyenv.load.shims ~/.local/env/jenv/shims`)"
fi
