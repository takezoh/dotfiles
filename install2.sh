#/bin/bash

ROOTDIR=$(cd `dirname $0` && pwd -P)
if [ -d /mnt/c/Windows ] && ! command cmd.exe /d /c openfiles >nul 2>nul; then
	cmd.exe /d /c setx WSLENV USERNAME/u:USERPROFILE/pu:APPDATA/pu:LOCALAPPDATA/pu:PROGRAMFILES/pu:ANDROID_HOME/pu:ANDROID_NDK_ROOT/pu
	powershell.exe -Command Start-Process -FilePath wsl -ArgumentList \"-d\",\"$WSL_DISTRO_NAME\",\"-e\",\"bash\",\"$ROOTDIR/$0\" -Verb RunAs
	exit 0
fi

(
	set -ex

	distribution=
	case "$OSTYPE" in
	darwin*)
		distribution=darwin
		;;
	linux*)
		distribution=$(cat /etc/os-release | grep -e '^ID=' | awk -F = '{ print $2 }')
		;;
	freebsd*)
		distribution=freebsd
		;;
	esac

	sudo -v

	for d in `command ls -d $ROOTDIR/misc/install/scripts/*`; do
		test -f $d/main.sh && source $d/main.sh
		test -f $d/$distribution.sh && source $d/$distribution.sh
		test -d /mnt/c/Windows && test -f $d/windows.sh && source $d/windows.sh
	done
)
read -p "Press any key to finish . . ."
