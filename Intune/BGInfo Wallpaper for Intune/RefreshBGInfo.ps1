# Writes the active IPv4 address and the machine serial number into the registry so
# BGInfo can read them as "Registry value" fields, then refreshes the BGInfo wallpaper.
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

# Collect the machine serial number from the BIOS/SMBIOS (readable by standard users).
$serial = (Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
if ([string]::IsNullOrWhiteSpace($serial)) { $serial = 'N/A' }

# Store the values where the BGInfo registry-value fields read from.
New-Item -Path 'HKCU:\Software\BGInfo' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\BGInfo' -Name 'IPv4' -Value $value
Set-ItemProperty -Path 'HKCU:\Software\BGInfo' -Name 'SerialNumber' -Value $serial

# Regenerate the wallpaper with the current values.
& "$InstallFolder\Bginfo64.exe" "$InstallFolder\Company.bgi" /timer:0 /silent /nolicprompt
