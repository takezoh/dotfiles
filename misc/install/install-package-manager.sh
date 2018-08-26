#!/bin/bash
set -ex

cd $(cd `dirname $0` && pwd -P)
source ../../config/zsh/environment.sh

darwin() {
	if ! type brew >/dev/null 2>&1; then
		if xcode-select --install >/dev/null 2>&1; then
			return 1
		else
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		fi
	fi
	brew update
	brew upgrade
	return 0
}

freebsd() {
	return 0
}

linux() {
	sudo apt install -y software-properties-common

	find /etc/apt/sources.list.d -type f -name "*.list" -print0 | \
		while read -d $'\0' file; do
			awk -F/ '/deb / && /ppa\.launchpad\.net/ {system("sudo add-apt-repository --remove ppa:"$4"/"$5)}' "$file"
		done

	sudo add-apt-repository -y ppa:git-core/ppa
	sudo add-apt-repository -y ppa:neovim-ppa/unstable
	sudo apt update -y
	sudo apt upgrade -y
	return 0
}

windows() {
	return 0
}

wsl() {
	return 0
}

cygwin() {
	return 0
}

for platform in ${_platforms[@]}; do
	if type $platform >/dev/null 2>&1; then
		$platform
	fi
done

hash -r
