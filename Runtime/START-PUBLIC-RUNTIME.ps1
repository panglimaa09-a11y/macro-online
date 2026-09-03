$ErrorActionPreference = 'Stop'
$Base = Split-Path -Parent $PSScriptRoot
$Cloudflared = Join-Path $Base 'Runtime\cloudflared.exe'

Write-Host '========================================' -ForegroundColor Cyan
Write-Host '      MACRO ONLINE PUBLIC RUNTIME' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

if (!(Test-Path $Cloudflared)) {
    Write-Host '[DOWNLOAD] cloudflared.exe...' -ForegroundColor Yellow
    $url = 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe'
    Invoke-WebRequest -Uri $url -OutFile $Cloudflared
}

if (!(Test-Path (Join-Path $Base 'Runtime\MacroOnline.Runtime.csproj'))) {
    throw 'Runtime project tidak ditemukan.'
}

Write-Host '[BUILD] Runtime...' -ForegroundColor Yellow
dotnet build (Join-Path $Base 'Runtime\MacroOnline.Runtime.csproj') -c Debug

Write-Host ''
Write-Host '[START] Runtime lokal...' -ForegroundColor Green
$runtime = Start-Process -FilePath 'dotnet' -ArgumentList @('run','--project',(Join-Path $Base 'Runtime\MacroOnline.Runtime.csproj'),'--no-build') -PassThru

Start-Sleep -Seconds 3

Write-Host ''
Write-Host '[START] Secure public tunnel...' -ForegroundColor Green
Write-Host 'Tunggu sampai URL trycloudflare.com muncul.' -ForegroundColor Yellow
Write-Host ''

& $Cloudflared tunnel --url http://127.0.0.1:17477

if (!$runtime.HasExited) {
    Stop-Process -Id $runtime.Id -Force -ErrorAction SilentlyContinue
}
