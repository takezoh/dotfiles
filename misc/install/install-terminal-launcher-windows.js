var fs = WScript.CreateObject("Scripting.FileSystemObject")
var WshShell = WScript.CreateObject("WScript.Shell")
var RootDir = fs.getParentFolderName(WScript.ScriptFullName) + "\\..\\.."
var WslDir = RootDir + "\\config\\mintty"


function MakeTerminalLink(Name) {
  var TempPath = fs.GetSpecialFolder(2) + "\\Mintty - " + Name + ".lnk"
  var lnk = WshShell.CreateShortcut(TempPath)
  var Terminal = "%LOCALAPPDATA%\\wsltty\\bin\\mintty.exe"
  var Icon = WslDir + "\\" + Name + ".ico"
  var Shell = "/usr/bin/zsh --login"
  //var Command = " -i \"" + Icon + "\" --WSL=\"" + Name + "\" --configdir=\"" + WslDir + "\" -~ " + Shell
  var Command = " -i \"" + Icon + "\" --WSL= --configdir=\"" + WslDir + "\" -~ " + Shell
  lnk.TargetPath = Terminal
  lnk.Arguments = Command
  lnk.IconLocation = Icon
  lnk.Save()
  WshShell.Run("cmd /c move \"" + TempPath + "\" \"%APPDATA%\\Microsoft\\Windows\\Start Menu\\Programs\\\"", 0)
}

MakeTerminalLink("Ubuntu")
//MakeTerminalLink("ArchLinux")
