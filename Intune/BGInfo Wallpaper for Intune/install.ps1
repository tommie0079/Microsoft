$InstallFolder = "C:\Program Files\BGInfo"

New-Item -Path $InstallFolder -ItemType Directory -Force

Copy-Item "$PSScriptRoot\Bginfo64.exe" $InstallFolder -Force
Copy-Item "$PSScriptRoot\Company.bgi" $InstallFolder -Force
Copy-Item "$PSScriptRoot\RefreshBGInfo.ps1" $InstallFolder -Force

# The refresh script writes the current IPv4 to the registry, then runs BGInfo.
# This avoids the deprecated/unsaved VBScript field and keeps the value current.
$RefreshScript = "$InstallFolder\RefreshBGInfo.ps1"
$RunCommand    = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RefreshScript`""

New-ItemProperty `
    -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" `
    -Name "BGInfo" `
    -PropertyType String `
    -Value $RunCommand `
    -Force

# Run BGInfo now in the active user's session.
# Intune runs this script as SYSTEM, so a direct call would apply the wallpaper to
# session 0 (SYSTEM), not the logged-on user. A temporary scheduled task set to run as
# the interactive user applies it to the desktop the user actually sees.
$TaskName = "BGInfo-RunOnce"

# Detect the currently logged-on interactive user (if any).
$LoggedOnUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName

if ($LoggedOnUser) {
    $Action    = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RefreshScript`""
    $Principal = New-ScheduledTaskPrincipal -UserId $LoggedOnUser -RunLevel Limited

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Force | Out-Null
    Start-ScheduledTask -TaskName $TaskName

    # Give it a moment to launch, then clean up the temporary task.
    Start-Sleep -Seconds 5
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
}
else {
    # No interactive user (e.g. install during OOBE/before logon).
    # The HKLM Run key above will apply BGInfo at the next user logon.
    Write-Output "No interactive user logged on; BGInfo will apply at next logon."
}
