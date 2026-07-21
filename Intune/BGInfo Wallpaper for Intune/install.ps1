$InstallFolder = "C:\Program Files\BGInfo"

# The corporate background image BGInfo composites its info fields on top of.
# Set the .bgi Background to "Copy existing settings" so BGInfo uses this file as the
# base (RefreshBGInfo.ps1 points BGInfo at it before each run). Change the image by
# editing $ImageUrl; a "background.bmp" bundled next to this script is used only if the
# download fails.
$BackgroundImage = "$InstallFolder\background.bmp"
$ImageUrl        = "https://github.com/user-attachments/files/30001294/BGInfo.bmp"

New-Item -Path $InstallFolder -ItemType Directory -Force

Copy-Item "$PSScriptRoot\Bginfo64.exe" $InstallFolder -Force
Copy-Item "$PSScriptRoot\Company.bgi" $InstallFolder -Force
Copy-Item "$PSScriptRoot\RefreshBGInfo.ps1" $InstallFolder -Force

# Download the background image from $ImageUrl. Runs as SYSTEM, so the file lands in
# Program Files and is readable by every user's refresh at logon. If the download fails
# (e.g. no network during Autopilot/ESP), fall back to a "background.bmp" bundled in the
# package.
$downloaded = $false
if ($ImageUrl) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $ImageUrl -OutFile $BackgroundImage -UseBasicParsing
        $downloaded = $true
    }
    catch {
        Write-Output "Failed to download background image from $ImageUrl : $($_.Exception.Message)"
    }
}
if (-not $downloaded -and (Test-Path -LiteralPath "$PSScriptRoot\background.bmp")) {
    Copy-Item "$PSScriptRoot\background.bmp" $BackgroundImage -Force
}

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
