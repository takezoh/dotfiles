var fs = new ActiveXObject("Scripting.FileSystemObject")
var WshShell = new ActiveXObject("WScript.Shell");

// var Terminal = "%LOCALAPPDATA%\\wsltty\\bin\\mintty.exe"
// var Icon = "-i " + fs.getParentFolderName(WScript.ScriptFullName) + "\\bash.ico"
// var Config = "--configdir=" + fs.getParentFolderName(WScript.ScriptFullName)
// var Shell = "/usr/bin/zsh --login"
var Command = "bash -c \"SHELL=/usr/bin/zsh DISPLAY=localhost:0.0 gnome-terminal\" -l && wait"

// WshShell.Run("cmd /c start " + Command, 0);
WshShell.Run(Command, 0);
