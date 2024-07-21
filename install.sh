#!/bin/bash

set -ex

darwin() {
	if ! type brew >/dev/null 2>&1; then
		xcode-select --install >/dev/null || true
		# if ! xcode-select --install >/dev/null 2>&1; then
		#  	return 1
		# fi
		# /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	fi
	brew update
	brew install ansible
}

ubuntu() {
	sudo apt update -y
	sudo apt install -y python3 python3-pip
	sudo apt install -y software-properties-common
	# sudo apt-add-repository -y ppa:ansible/ansible
	sudo apt update -y

	if ! type brew >/dev/null 2>&1; then
		sudo apt install -y build-essential curl file git
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
	fi
	sudo apt install -y ansible
}

arch() {
	yes | sudo pacman -Sy

	if ! type aurman >/dev/null 2>&1; then
		yes | sudo pacman -S git
		gpg --recv-keys 4C3CE98F9579981C21CA1EC3465022E743D71E39
		cd `mktemp -d`
		git clone https://aur.archlinux.org/aurman.git
		cd aurman
		yes | makepkg -si
	fi

	sudo pacman -S --noconfirm ansible
}

sudo -v

if ! type ansible-playbook >/dev/null 2>&1; then
	case "$OSTYPE" in
	darwin*)
		darwin
		;;
	linux*)
		$(cat /etc/os-release | grep -e '^ID=' | awk -F = '{ print $2 }')
		;;
	freebsd*)
		;;
	esac
	hash -r
fi

base_dir=$(cd `dirname $0` && pwd -P)
test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
pip3 install ansible
ansible-playbook --module-path=$base_dir/external/ansible/plugins/modules $base_dir/misc/install/ansible/playbook.yml \
	-e ansible_python_interpreter=/usr/bin/python3

bash $base_dir/misc/pygments/setup.sh

bash $base_dir/install2.sh

