var fs = WScript.CreateObject("Scripting.FileSystemObject")
var WshShell = WScript.CreateObject("WScript.Shell")
var RootDir = fs.getParentFolderName(WScript.ScriptFullName) + "\\..\\..\\"
var WslDir = RootDir + "\\config\\mintty\\"

function MakeTerminalLink(Name) {
  var TempPath = fs.GetSpecialFolder(2) + "\\Mintty - " + Name + ".lnk"
  var lnk = WshShell.CreateShortcut(TempPath)
  lnk.TargetPath = WslDir + "open-wsltty.js"
  lnk.Arguments = "\"" + Name + "\""
  lnk.IconLocation = WslDir + Name + ".ico"
  lnk.Save()
  WshShell.Run("cmd /c move \"" + TempPath + "\" \"%USERPROFILE%\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\\"", 0)
}

MakeTerminalLink("Ubuntu-18.04")
MakeTerminalLink("ArchLinux")
