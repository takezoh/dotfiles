#/bin/bash
set -ex

cmd.exe /d /c rmdir /q /s '%USERPROFILE%\.ssh' || true
cmd.exe /d /c mklink /d '%USERPROFILE%\.ssh' $(wslpath -aw $HOME/.ssh)

cmd.exe /d /c del /q '%USERPROFILE%\.vsvimrc' || true
cmd.exe /d /c mklink '%USERPROFILE%\.vsvimrc' $(wslpath -aw $ROOTDIR/config/non-xdg/vsvimrc)

cmd.exe /d /c del /q '%USERPROFILE%\.gitconfig' || true
cmd.exe /d /c mklink '%USERPROFILE%\.gitconfig' $(wslpath -aw $ROOTDIR/config/non-xdg/gitconfig)
