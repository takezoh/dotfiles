var fs = WScript.CreateObject("Scripting.FileSystemObject")
var WshShell = WScript.CreateObject("WScript.Shell")
var RootDir = fs.getParentFolderName(WScript.ScriptFullName) + "\\..\\..\\"
var WslDir = RootDir + "\\config\\mintty\\"

function MakeTerminalLink(Name) {
  var TempPath = fs.GetSpecialFolder(2) + "\\" + Name + ".lnk"
  var lnk = WshShell.CreateShortcut(TempPath)
  lnk.TargetPath = WslDir + "open-" + Name + ".js"
  lnk.IconLocation = WslDir + "bash.ico"
  lnk.Save()
  WshShell.Run("cmd /c move " + TempPath + " \"%USERPROFILE%\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\\"", 0)
}

MakeTerminalLink("gnome-terminal")
MakeTerminalLink("wsl-terminal")