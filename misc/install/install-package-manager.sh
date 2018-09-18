#!/bin/bash
set -ex

cd $(cd `dirname $0` && pwd -P)
source ../../config/zsh/environment.sh

darwin() {
	# if [ ! -f /Library/LaunchDaemons/com.apple.relatime.plist ]; then
		# sudo cp darwin_files/com.apple.relatime.plist /Library/LaunchDaemons
	# fi

	if ! type brew >/dev/null 2>&1; then
		if xcode-select --install >/dev/null 2>&1; then
			return 1
		else
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		fi
	fi
	brew update
	brew upgrade
}

freebsd() {
	return 0
}

arch() {
	sudo sed -i -e 's/#ja_JP.UTF8 .*$/ja_JP.UTF8 UTF8/' /etc/locale.gen
	locale-gen

	# sudo pacman -g
	yes | sudo pacman -Syyu
	# yes | sudo paccache -r
	# yes | sudo paccache -ruk0

	if ! type aurman >/dev/null 2>&1; then (
		yes | sudo pacman -S git
		gpg --recv-keys 4C3CE98F9579981C21CA1EC3465022E743D71E39
		cd `mktemp -d`
		git clone https://aur.archlinux.org/aurman.git
		cd aurman
		yes | makepkg -si
		hash -r
	) fi

	aurman -Syyu --noconfirm
}

ubuntu() {
	sudo apt install -y software-properties-common

	find /etc/apt/sources.list.d -type f -name "*.list" -print0 | \
		while read -d $'\0' file; do
			awk -F/ '/deb / && /ppa\.launchpad\.net/ {system("sudo add-apt-repository --remove ppa:"$4"/"$5)}' "$file"
		done

	sudo add-apt-repository -y ppa:git-core/ppa
	sudo add-apt-repository -y ppa:neovim-ppa/unstable
	sudo apt update -y
	sudo apt upgrade -y
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

if type $1 >/dev/null 2>&1; then
	$1
fi

hash -r
