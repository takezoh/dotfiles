#/bin/bash
set -ex

win_vscode_datapath=$(powershell.exe Write-Host -NoNewline '$env:APPDATA\Code')
win_vscode_settings_source=$(wslpath -aw $ROOTDIR/config/vscode)

cmd.exe /d /c mkdir $win_vscode_datapath || true
cmd.exe /d /c rmdir /q /s $win_vscode_datapath'\User' || true
cmd.exe /d /c mklink /d $win_vscode_datapath'\User' $win_vscode_settings_source
