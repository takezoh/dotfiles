var fs = new ActiveXObject("Scripting.FileSystemObject")
var shell = new ActiveXObject("WScript.Shell")

var Distro = WScript.Arguments(0)

shell.CurrentDirectory = fs.getParentFolderName(WScript.ScriptFullName)
shell.Run("wsl -d " + Distro + " -- ./rc.init \"" + Distro + "\"", 0, true)
