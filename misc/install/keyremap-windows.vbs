Set oLocator = WScript.CreateObject("WbemScripting.SWbemLocator")
Set oService = oLocator.ConnectServer(, "root\default")
Set oClass = oService.Get("StdRegProv")

Const HKEY_LOCAL_MACHINE = &H80000002

' LWin => Zenkaku/Hankaku
' RWin => Hiragana

bBinaryValue = Array( _
	&h00,&h00, &h00,&h00, &h00,&h00, &h00,&h00, _
	&h03,&h00, &h00,&h00, _
	&h7b,&h00, &h5b,&he0, _
	&h79,&h00, &h5c,&he0, _
	&h00,&h00, &h00,&h00 _
)

oClass.SetBinaryValue HKEY_LOCAL_MACHINE, "SYSTEM\CurrentControlSet\Control\Keyboard Layout", "Scancode Map", bBinaryValue
