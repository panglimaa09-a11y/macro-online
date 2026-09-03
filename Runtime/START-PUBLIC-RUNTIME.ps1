$ErrorActionPreference = 'Stop'
$Base = Split-Path -Parent $PSScriptRoot
$Cloudflared = Join-Path $PSScriptRoot 'cloudflared.exe'

Write-Host '========================================' -ForegroundColor Cyan
Write-Host '      MACRO ONLINE PUBLIC RUNTIME' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

if (!(Test-Path $Cloudflared)) {
    Write-Host '[DOWNLOAD] cloudflared.exe...' -ForegroundColor Yellow
    $url = 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe'
    Invoke-WebRequest -Uri $url -OutFile $Cloudflared
}

$csproj = Join-Path $PSScriptRoot 'MacroOnline.Runtime.csproj'
if (!(Test-Path $csproj)) { throw "Runtime project tidak ditemukan: $csproj" }

$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$token = [Convert]::ToBase64String($bytes).Replace('+','-').Replace('/','_').TrimEnd('=')

Write-Host '[BUILD] Runtime...' -ForegroundColor Yellow
dotnet build $csproj -c Debug
if ($LASTEXITCODE -ne 0) { throw 'Build Runtime gagal.' }

Write-Host ''
Write-Host '[START] Runtime lokal...' -ForegroundColor Green
$env:MACRO_ONLINE_TOKEN = $token
$runtime = Start-Process -FilePath 'dotnet' -ArgumentList @('run','--project',$csproj,'--no-build') -WorkingDirectory $Base -PassThru

Start-Sleep -Seconds 3

Write-Host ''
Write-Host '[START] Public HTTPS tunnel...' -ForegroundColor Green
Write-Host 'Tunggu URL trycloudflare.com...' -ForegroundColor Yellow
Write-Host ''

$log = Join-Path $env:TEMP 'macro-online-cloudflared.log'
if (Test-Path $log) { Remove-Item $log -Force }

$tunnel = Start-Process -FilePath $Cloudflared -ArgumentList @('tunnel','--url','http://127.0.0.1:17477','--no-autoupdate') -RedirectStandardError $log -PassThru

$publicUrl = $null
for ($i = 0; $i -lt 45; $i++) {
    Start-Sleep -Seconds 1
    if (Test-Path $log) {
        $text = Get-Content $log -Raw -ErrorAction SilentlyContinue
        $m = [regex]::Match($text,'https://[a-z0-9-]+\.trycloudflare\.com')
        if ($m.Success) { $publicUrl = $m.Value; break }
    }
}

if (!$publicUrl) {
    Write-Host '[ERROR] URL tunnel tidak ditemukan. Log:' -ForegroundColor Red
    if (Test-Path $log) { Get-Content $log -Tail 30 }
    if (!$runtime.HasExited) { Stop-Process -Id $runtime.Id -Force -ErrorAction SilentlyContinue }
    if (!$tunnel.HasExited) { Stop-Process -Id $tunnel.Id -Force -ErrorAction SilentlyContinue }
    exit 1
}

$wsUrl = $publicUrl -replace '^https://','wss://'
$connectUrl = "$wsUrl/?token=$token"

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host '         RUNTIME ONLINE' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host "PUBLIC URL : $publicUrl" -ForegroundColor White
Write-Host "WS URL     : $connectUrl" -ForegroundColor White
Write-Host ''
Write-Host 'SALIN WS URL di atas ke Dashboard Macro Online.' -ForegroundColor Yellow
Write-Host 'Jangan bagikan URL/token ini ke orang lain.' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Tekan Ctrl+C untuk menghentikan Runtime + tunnel.' -ForegroundColor Cyan
Write-Host ''

try {
    while (!$runtime.HasExited -and !$tunnel.HasExited) { Start-Sleep -Seconds 2 }
}
finally {
    if (!$runtime.HasExited) { Stop-Process -Id $runtime.Id -Force -ErrorAction SilentlyContinue }
    if (!$tunnel.HasExited) { Stop-Process -Id $tunnel.Id -Force -ErrorAction SilentlyContinue }
}
