$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot
$Launcher = Join-Path $Root 'START-MACRO-ONLINE.ps1'
if (!(Test-Path $Launcher)) { throw "START-MACRO-ONLINE.ps1 tidak ditemukan: $Launcher" }

$Key = 'HKCU:\Software\Classes\macroonline'
New-Item -Path $Key -Force | Out-Null
Set-ItemProperty -Path $Key -Name '(Default)' -Value 'URL:Macro Online Launcher'
Set-ItemProperty -Path $Key -Name 'URL Protocol' -Value ''
New-Item -Path "$Key\shell\open\command" -Force | Out-Null
$cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$Launcher`""
Set-ItemProperty -Path "$Key\shell\open\command" -Name '(Default)' -Value $cmd

Write-Host ''
Write-Host 'MACRO ONLINE START BUTTON AKTIF' -ForegroundColor Green
Write-Host 'Protocol macroonline:// sudah terdaftar.' -ForegroundColor Cyan
Write-Host 'Sekarang tombol START di website dapat membuka launcher Windows.' -ForegroundColor White
Write-Host ''
Read-Host 'Tekan Enter untuk keluar'