# Writes the active IPv4 address and the machine serial number into the registry so
# BGInfo can read them as "Registry value" fields, then refreshes the BGInfo wallpaper.
# Runs in the logged-on user's context, so it writes to HKCU (no admin needed) and
# applies the wallpaper to the desktop the user actually sees.
#
# This build is designed to co-exist with the Intune/PersonalizationCSP "Desktop Image
# Url" policy. That policy locks the wallpaper to a fixed file path (DesktopImagePath)
# and normally overrides BGInfo. To make both work, we feed BGInfo's generated image
# INTO that enforced file, then ask Explorer to re-render it. Re-applying the *same*
# enforced path is allowed even while the wallpaper is locked, so the fresh IP/serial
# image shows without needing to reset the CSP cache (no admin required).
#
# IMPORTANT: set the "Desktop Image Url" policy value to exactly $EnforcedImage below.

$InstallFolder = "C:\Program Files\BGInfo"

# The single file the PersonalizationCSP "Desktop Image Url" policy points at
# (DesktopImageUrl / DesktopImagePath). BGInfo's output is copied here each refresh.
$EnforcedImage = "C:\ProgramData\BGInfo\wallpaper.bmp"

# The corporate background image install.ps1 placed/downloaded. BGInfo draws the info
# fields on top of it. Requires the .bgi Background to be "Copy existing settings".
$BackgroundImage = "$InstallFolder\background.bmp"

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

# Point BGInfo's base image at the corporate background before running it. With the .bgi
# Background set to "Copy existing settings", BGInfo reads this HKCU wallpaper value as
# the source and overlays the info fields on the corporate image (instead of black).
if (Test-Path -LiteralPath $BackgroundImage) {
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallPaper' -Value $BackgroundImage
}

# Regenerate the wallpaper with the current values. BGInfo composites the image and
# points HKCU\Control Panel\Desktop\WallPaper at the generated bitmap.
& "$InstallFolder\Bginfo64.exe" "$InstallFolder\Company.bgi" /timer:0 /silent /nolicprompt

# Feed BGInfo's freshly generated image into the policy-enforced file so the locked
# "Desktop Image Url" wallpaper reflects the current IP/serial. The refresh script owns
# this folder (it creates it on first run), so the user-context write needs no admin.
$generated = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'WallPaper' -ErrorAction SilentlyContinue).WallPaper
if ($generated -and (Test-Path -LiteralPath $generated)) {
    New-Item -Path (Split-Path -Parent $EnforcedImage) -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $generated -Destination $EnforcedImage -Force

    # Force Explorer to re-read the enforced file from disk. Changing the wallpaper to a
    # *different* path is blocked while locked, but re-applying the SAME enforced path is
    # allowed and re-renders the new bytes. SPI_SETDESKWALLPAPER = 0x0014;
    # SPIF_UPDATEINIFILE (1) | SPIF_SENDCHANGE (2) = 3.
    if (-not ('BGInfo.NativeWallpaper' -as [type])) {
        Add-Type -Namespace BGInfo -Name NativeWallpaper -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
'@
    }
    [BGInfo.NativeWallpaper]::SystemParametersInfo(0x0014, 0, $EnforcedImage, 3) | Out-Null
}
