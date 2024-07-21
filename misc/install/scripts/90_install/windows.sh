#/bin/bash
set -ex

win_libpath=$(powershell.exe Write-Host -NoNewline '$env:LOCALAPPDATA\WSL.local')
wsl_libpath=$(wslpath -u $win_libpath)
wsl_makefiles=(
  # wsl/global
  wsl/win32yank
  wsl/wsltty
)

cmd.exe /d /c mkdir $win_libpath'\bin' || true
cmd.exe /d /c mkdir $win_libpath'\opt' || true

for mk in ${wsl_makefiles[@]}; do
	BINDIR=$wsl_libpath/bin ROOT_DIRECTORY=$ROOTDIR make -f $ROOTDIR/misc/install/scripts/90_install/makefiles/$mk.mk -C $wsl_libpath/opt
done
