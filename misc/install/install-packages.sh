#!/bin/bash
set -ex

cd $(cd `dirname $0` && pwd -P)
source ../../config/zsh/environment.sh

darwin() {
	brew install "$@"
	return 0
}

freebsd() {
	return 0
}

linux() {
	sudo apt install -y "$@"
	return 0
}

# windows() {
	# return 0
# }

# wsl() {
	# return 0
# }

cygwin() {
	apt install "$@"
	return 0
}

for platform in ${_platforms[@]}; do
	if type $platform >/dev/null 2>&1; then
		$platform "$@"
		break
	fi
done

hash -r
