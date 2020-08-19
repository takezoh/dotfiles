Set fs = WScript.CreateObject("Scripting.FileSystemObject")
Set sh = WScript.CreateObject("WScript.Shell")
Set env = sh.Environment("PROCESS")

Dim Distro
Dim Terminal
Dim Icon
Dim Config
Dim Shell
Dim Command

Distro = WScript.Arguments(0)
Terminal = "%LOCALAPPDATA%\\wsltty\\bin\\mintty.exe"
Icon = fs.GetParentFolderName(WScript.ScriptFullName) & "\""" & Distro & ".ico"""
Config = fs.GetParentFolderName(WScript.ScriptFullName)
Shell = "/usr/bin/zsh --login"
Command = Terminal & " -i " & Icon & " --WSL=""" & Distro & """ --configdir=""" & Config & """ -~ " & Shell
'WScript.Echo Command

env.item("SHELL") = "/usr/bin/zsh"
env.item("WSLSHELL") = "/usr/bin/zsh"
' PATHを渡すとクラッシュ
'env.item("WSLENV") = "SHELL/u:WSLSHELL/u:PATH/lu:USERPROFILE/pu:APPDATA/pu:LOCALAPPDATA/pu:PROGRAMFILES/pu:ANDROID_HOME/pu:ANDROID_NDK_ROOT/pu"
env.item("WSLENV") = "SHELL/u:WSLSHELL/u:USERPROFILE/pu:APPDATA/pu:LOCALAPPDATA/pu:PROGRAMFILES/pu:ANDROID_HOME/pu:ANDROID_NDK_ROOT/pu"

sh.Run "cmd /c start " & Command, 0
