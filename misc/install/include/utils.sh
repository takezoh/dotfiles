#!/bin/bash
include_dir=$(cd `dirname ${BASH_SOURCE:-$0}` && pwd -P)
source $include_dir/../../../config/zsh/environment.sh

has-platform-symbol() {
	for p in ${_platforms[@]}; do
		[[ "$1" == "$p" ]] && return 0;
	done
	return 1
}

clean-symbolic-link() {
	find -L $1 -maxdepth 1 -type l -exec unlink {} \;
}
