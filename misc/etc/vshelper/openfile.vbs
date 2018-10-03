On Error Resume Next

Set objDTE = GetObject(, "VisualStudio.DTE.15.0")
If Err.Number<> 0 Then
    Set objDTE = CreateObject("VisualStudio.DTE.15.0")
    Err.Clear
End If

Dim fileName
Dim lineNumber
fileName = Wscript.Arguments(0)
lineNumber = int(Wscript.Arguments(1))

objDTE.MainWindow.Activate
objDTE.MainWindow.Visible = True
objDTE.UserControl = True

objDTE.ItemOperations.OpenFile fileName
objDTE.ActiveDocument.Selection.MoveToLineAndOffset lineNumber, 1
