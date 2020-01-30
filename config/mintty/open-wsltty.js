var fs = new ActiveXObject("Scripting.FileSystemObject")
var WshShell = new ActiveXObject("WScript.Shell");
var env = WshShell.Environment('PROCESS');

var Distro = WScript.Arguments(0)

var Terminal = "%LOCALAPPDATA%\\wsltty\\bin\\mintty.exe"
var Icon = fs.getParentFolderName(WScript.ScriptFullName) + "\\\"" + Distro + ".ico\""
var Config = fs.getParentFolderName(WScript.ScriptFullName)
var Shell = "/usr/bin/zsh --login"
var Command = Terminal + " -i " + Icon + " --WSL=\"" + Distro + "\" --configdir=" + Config + " -~ " + Shell

env.item("SHELL") = "/usr/bin/zsh"
env.item("WSLSHELL") = "/usr/bin/zsh"
env.item("WSLENV") = "SHELL/u:WSLSHELL/u:PATH/lu:USERPROFILE/pu:APPDATA/pu:LOCALAPPDATA/pu:PROGRAMFILES/pu:ANDROID_HOME/pu:ANDROID_NDK_ROOT/pu"

WshShell.Run("cmd /c start " + Command, 0);
