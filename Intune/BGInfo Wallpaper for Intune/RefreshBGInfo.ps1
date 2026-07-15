# Writes the active IPv4 address into the registry so BGInfo can read it as a
# "Registry value" field, then refreshes the BGInfo wallpaper.
# Runs in the logged-on user's context, so it writes to HKCU (no admin needed) and
# applies the wallpaper to the desktop the user actually sees.

$InstallFolder = "C:\Program Files\BGInfo"

# Collect only the "real" IPv4 address(es): adapters that are Up and have a default
# gateway. This excludes loopback, APIPA (169.254.x.x) and virtual adapters such as
# Hyper-V (vEthernet), WSL, VMware/VirtualBox, etc., which normally have no gateway.
$addresses = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
    Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } |
    ForEach-Object { $_.IPv4Address.IPAddress } |
    Where-Object { $_ -and $_ -ne '127.0.0.1' -and $_ -notlike '169.254.*' }

$value = ($addresses -join ', ')
if ([string]::IsNullOrWhiteSpace($value)) { $value = 'N/A' }

# Store it where the BGInfo "IPv4" registry-value field reads from.
New-Item -Path 'HKCU:\Software\BGInfo' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\BGInfo' -Name 'IPv4' -Value $value

# Regenerate the wallpaper with the current values.
& "$InstallFolder\Bginfo64.exe" "$InstallFolder\Company.bgi" /timer:0 /silent /nolicprompt
