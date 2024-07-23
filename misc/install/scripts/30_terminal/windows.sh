#/bin/bash
set -ex

#windowsterminal_package_path=$(powershell.exe Write-Host -NoNewline '$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe')
#windowsterminal_config_path=$(wslpath -aw $ROOTDIR/config/WindowsTerminal)

#cmd.exe /d /c rmdir /q /s $windowsterminal_package_path'\LocalState' || true
#cmd.exe /d /c mklink /d $windowsterminal_package_path'\LocalState' $windowsterminal_config_path
