#!/bin/bash
set -ex

install_dir=$(cd `dirname ${BASH_SOURCE:-$0}` && pwd -P)/..

source $install_dir/../../config/zsh/environment.sh
source $install_dir/include/utils.sh

install

for platform in ${_platforms[@]}; do
	if type "install_${platform}" >/dev/null 2>&1; then
		install_${platform}
	fi
done

$install_dir/install-package-manager.sh

for platform in ${_platforms[@]}; do
	if type "add_packages_${platform}" >/dev/null 2>&1; then
		add_packages_${platform}
		$install_dir/install-packages.sh ${packages[@]}
	fi
done

for platform in ${_platforms[@]}; do
	if type "post_install_${platform}" >/dev/null 2>&1; then
		post_install_${platform}
	fi
done
