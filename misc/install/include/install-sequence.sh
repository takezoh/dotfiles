#!/bin/bash
set -ex

install_dir=$(cd `dirname ${BASH_SOURCE:-$0}` && pwd -P)/..

source $install_dir/../../config/zsh/environment.sh
source $install_dir/include/utils.sh

linux-distro-name() {
	cat /etc/os-release | grep -e '^ID=' | awk -F = '{ print $2 }'
}

execute() {
	if type "${1}_${2}" >/dev/null 2>&1; then
		${1}_${2}
	fi
	if [ "$2" = "linux" ]; then
		local distro=`linux-distro-name`
		if type "${1}_${distro}" >/dev/null 2>&1; then
			${1}_${distro}
		fi
	fi
}

install

for platform in ${_platforms[@]}; do
	execute install $platform
done

for platform in ${_platforms[@]}; do
	if [ "$platform" = "linux" ]; then
		$install_dir/install-package-manager.sh `linux-distro-name`
	else
		$install_dir/install-package-manager.sh $platform
	fi
	execute add_packages $platform
done

for platform in ${_platforms[@]}; do
	execute post_install $platform
done
