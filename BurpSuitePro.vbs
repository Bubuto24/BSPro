command = "powershell -Nologo -File .\CheckUpdate.ps1"
' Debugging purposes
If WScript.Arguments.Count = 1 Then
    If LCase(WScript.Arguments(0)) = "-debug" Then
        command = command & " -debug"
    End If
End If

Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")

If fso.FolderExists("C:/Burp") Then
    userResult = MsgBox("Check update for Burp?", vbYesNoCancel + vbQuestion, "Burp Suite Professional")
    If userResult = vbNo Then
        LaunchBurp
        WScript.Quit
    ElseIf userResult = vbCancel Then
        WScript.Quit
    End If
Else
    MsgBox "Burp folder is not found (C:/Burp)", vbCritical, "Error"
    WScript.Quit
End If

ExitCode = WshShell.Run(command, 1, vbTrue)

Select Case ExitCode
    Case 0
        LaunchBurp
    Case -1
        ' vbs doesn't support in opening powershell in administrator mode directly (requires nested calling)
        ' one workaround is to open burpsuiteupdate.ps1 in user mode, then elevate to admin mode
        ' so the ps instance in user mode will close and a new instance in admin mode will be generated
        WshShell.Run "powershell -Nologo -File .\BurpSuiteUpdate.ps1", 1
    Case -2
        WScript.Quit
    Case Else
        MsgBox "Something wrong has occurred. (" & ExitCode & ")", vbCritical, "Error"
        WScript.Quit
End Select

Set WshShell = Nothing
Set fso = Nothing

Sub LaunchBurp()
    WshShell.Run chr(34) & "C:\burp\burp.bat" & Chr(34), 0
End Sub
