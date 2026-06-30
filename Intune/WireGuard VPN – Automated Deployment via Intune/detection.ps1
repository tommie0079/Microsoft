$wireGuardExe = "C:\Program Files\WireGuard\wireguard.exe"
$configPath = "C:\ProgramData\WireGuard\CorporateVPN.conf"

if ((Test-Path $wireGuardExe) -and (Test-Path $configPath)) {
    Write-Output "Detected"
    exit 0
}

exit 1
