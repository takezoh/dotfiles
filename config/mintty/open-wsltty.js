var fs = new ActiveXObject("Scripting.FileSystemObject")
var WshShell = new ActiveXObject("WScript.Shell");
var env = WshShell.Environment('PROCESS');

var Distro = WScript.Arguments(0)

var Terminal = "%LOCALAPPDATA%\\wsltty\\bin\\mintty.exe"
var Icon = "-i " + fs.getParentFolderName(WScript.ScriptFullName) + "\\\"" + Distro + ".ico\""
var Config = "--configdir=" + fs.getParentFolderName(WScript.ScriptFullName)
var Shell = "/usr/bin/zsh --login"
var Command = Terminal + " " + Icon + " --WSL=\"" + Distro + "\" " + Config + " -~ " + Shell

env.item("SHELL") = "/usr/bin/zsh"
env.item("WSLENV") = "SHELL/u:PATH/lu:USERPROFILE/pu"

WshShell.Run("cmd /c start " + Command, 0);
