
Dim prefix, suffix, fileName, today, year, month, day

' This should be the path to the web server'
filePath = "c:\temp"

' This is the mediapk file descriptor and extention'
filePrefix = "dvd2avi"
fileSuffix = ".txt"

' This is the path to the mkpak.exe file'
mkpakPath = "C:\svn\src\mediapak\trunk\mkpak.exe"

' This is the paths to search to generate the mediapak'
mediaPath = "c:\temp c:\tmp"

'create file name
today = Date
year = CStr(DatePart("yyyy", today))
month = Right("0" & CStr(DatePart("m", today)), 2)
day = Right("0" & CStr(DatePart("d", today)), 2)

fileName = filePath & "\" & filePrefix & "-" & year & month & day & fileSuffix

'Cscript.Echo ( filename )

Set objShell = CreateObject("WScript.Shell")
objShell.Exec "%COMSPEC% /k " & mkpakPath & " " & mediaPath & " > " & filename




