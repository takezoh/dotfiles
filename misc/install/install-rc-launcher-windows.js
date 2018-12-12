var fs = WScript.CreateObject("Scripting.FileSystemObject")
var WshShell = WScript.CreateObject("WScript.Shell")
var RootDir = fs.getParentFolderName(WScript.ScriptFullName) + "\\..\\..\\"
var TargetDir = RootDir + "\\misc\\etc\\wsl\\"

function MakeLink(Name) {
  var TempPath = fs.GetSpecialFolder(2) + "\\rc." + Name + ".lnk"
  var lnk = WshShell.CreateShortcut(TempPath)
  lnk.TargetPath = TargetDir + "rc.js"
  lnk.Arguments = "\"" + Name + "\""
  // lnk.IconLocation = WslDir + Name + ".ico"
  lnk.Save()
  WshShell.Run("cmd /c move \"" + TempPath + "\" \"%USERPROFILE%\\AppData\\Roaming\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\\"", 0)
}

MakeLink("Ubuntu-18.04")
MakeLink("ArchLinux")
