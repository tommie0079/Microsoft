$InstallFolder = "C:\Program Files\BGInfo"

# Stop any running BGInfo instance so files aren't locked and the wallpaper stops refreshing.
Get-Process -Name "Bginfo64", "Bginfo" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Remove the logon autorun entry.
Remove-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
    -Name "BGInfo" `
    -ErrorAction SilentlyContinue

# Remove the temporary run-once task if it was left behind.
Unregister-ScheduledTask -TaskName "BGInfo-RunOnce" -Confirm:$false -ErrorAction SilentlyContinue

# Remove the installed files.
Remove-Item $InstallFolder -Recurse -Force -ErrorAction SilentlyContinue

# Remove the IPv4 value BGInfo read from.
Remove-Item -Path "HKCU:\Software\BGInfo" -Recurse -Force -ErrorAction SilentlyContinue

# Remove the policy-enforced image BGInfo fed the "Desktop Image Url" wallpaper.
# (Remove/repoint the PersonalizationCSP policy separately in Intune.)
Remove-Item -Path "C:\ProgramData\BGInfo" -Recurse -Force -ErrorAction SilentlyContinue

# Clear the BGInfo-generated (black) wallpaper so the desktop is no longer branded by BGInfo.
Remove-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Wallpaper" -ErrorAction SilentlyContinue
