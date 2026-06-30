<#
.SYNOPSIS
    Fixed All-in-One WireGuard Deployment Script for Intune Win32
#>

$MSIFile = "wireguard-amd64-1.1.msi"
$TunnelName = "CorporateVPN"

$WireGuardExe = "C:\Program Files\WireGuard\wireguard.exe"
$ConfigDirectory = "C:\ProgramData\WireGuard"
$ConfigPath = Join-Path $ConfigDirectory "$TunnelName.conf"
$TunnelServiceName = 'WireGuardTunnel$' + $TunnelName
$PackagedConfigPath = Join-Path $PSScriptRoot "company-vpn.conf"
$LogFile = "C:\Windows\Temp\WireGuard_Intune_Install.log"
$TranscriptFile = "C:\Windows\Temp\WireGuard_Intune_Install_Transcript.log"
$MSILogFile = "C:\Windows\Temp\WireGuard_MSI_Install.log"
$TranscriptStarted = $false
$TunnelUninstallTimeoutSeconds = 30
$TunnelInstallTimeoutSeconds = 60
$TunnelServiceDetectionTimeoutSeconds = 15

function Write-Log {
    param(
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $Message"

    Write-Output $entry
    Add-Content -Path $LogFile -Value $entry
}

function Invoke-ProcessWithTimeout {
    param(
        [string]$FilePath,
        [string]$ArgumentList,
        [int]$TimeoutSeconds,
        [string]$OperationName
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -NoNewWindow

    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Write-Log "$OperationName timed out after $TimeoutSeconds seconds. Stopping process $($process.Id)."

        try {
            Stop-Process -Id $process.Id -Force -ErrorAction Stop
        } catch {
            Write-Log "Failed to stop timed out process $($process.Id): $($_.Exception.Message)"
        }

        return [pscustomobject]@{
            ExitCode = 258
            TimedOut = $true
        }
    }

    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        TimedOut = $false
    }
}

function Wait-ForTunnelService {
    param(
        [string]$ServiceName,
        [int]$TimeoutSeconds
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $deadline) {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-Log "Tunnel service $ServiceName detected with status $($service.Status)."
            return $true
        }

        Start-Sleep -Seconds 1
    }

    return $false
}

# Enable basic local logging for troubleshooting
New-Item -Path $LogFile -ItemType File -Force | Out-Null
try {
    Start-Transcript -Path $TranscriptFile -Append | Out-Null
    $TranscriptStarted = $true
} catch {
    Write-Output "Start-Transcript failed: $($_.Exception.Message)"
}

Write-Log "--- Starting WireGuard Installation Deployment ---"
Write-Log "PowerShell path: $($PSHOME)"
Write-Log "Script root: $PSScriptRoot"
Write-Log "MSI log path: $MSILogFile"
Write-Log "Config path: $ConfigPath"

# 1. Install the WireGuard MSI Silently
if (!(Test-Path $WireGuardExe)) {
    Write-Log "WireGuard.exe not found. Proceeding with silent MSI installation..."
    # Using $PSScriptRoot ensures it finds the MSI file inside the Intune folder package
    $msiProcess = Start-Process msiexec.exe -ArgumentList "/i `"$PSScriptRoot\$MSIFile`" /qn /norestart /L*v `"$MSILogFile`" DO_NOT_LAUNCH=1" -Wait -PassThru
    Write-Log "msiexec exit code: $($msiProcess.ExitCode)"
    if ($msiProcess.ExitCode -ne 0) {
        Write-Log "MSI installation failed. Review verbose MSI log at $MSILogFile"
        if ($TranscriptStarted) { Stop-Transcript | Out-Null }
        Exit $msiProcess.ExitCode
    }
} else {
    Write-Log "WireGuard client is already present on this device."
}

# 2. Verify installation succeeded before injecting the VPN profile
if (Test-Path $WireGuardExe) {
    Write-Log "WireGuard.exe presence verified. Preparing profile configuration..."

    New-Item -Path $ConfigDirectory -ItemType Directory -Force | Out-Null

    if (!(Test-Path $PackagedConfigPath)) {
        Write-Log "Packaged profile not found at $PackagedConfigPath"
        if ($TranscriptStarted) { Stop-Transcript | Out-Null }
        Exit 1
    }

    Copy-Item -Path $PackagedConfigPath -Destination $ConfigPath -Force
    Write-Log "Copied packaged profile from $PackagedConfigPath to $ConfigPath"

    $existingTunnelService = Get-Service -Name $TunnelServiceName -ErrorAction SilentlyContinue
    if ($existingTunnelService) {
        Write-Log "Removing existing tunnel service named $TunnelName"
        $removeProcess = Invoke-ProcessWithTimeout -FilePath $WireGuardExe -ArgumentList "/uninstalltunnelservice $TunnelName" -TimeoutSeconds $TunnelUninstallTimeoutSeconds -OperationName "Tunnel service uninstall"
        Write-Log "Tunnel service uninstall exit code: $($removeProcess.ExitCode)"
        if ($removeProcess.TimedOut) {
            Write-Log "Tunnel service uninstall did not complete before timeout. Leaving existing profile at $ConfigPath"
            if ($TranscriptStarted) { Stop-Transcript | Out-Null }
            Exit $removeProcess.ExitCode
        }
    } else {
        Write-Log "No existing tunnel service named $TunnelName was found. Skipping uninstall step."
    }

    Write-Log "Registering WireGuard tunnel service from $ConfigPath"
    $tunnelProcess = Invoke-ProcessWithTimeout -FilePath $WireGuardExe -ArgumentList "/installtunnelservice `"$ConfigPath`"" -TimeoutSeconds $TunnelInstallTimeoutSeconds -OperationName "Tunnel service registration"
    Write-Log "Tunnel service install exit code: $($tunnelProcess.ExitCode)"
    if ($tunnelProcess.TimedOut) {
        Write-Log "Tunnel service registration timed out. Profile retained at $ConfigPath"
        if ($TranscriptStarted) { Stop-Transcript | Out-Null }
        Exit $tunnelProcess.ExitCode
    }
    if ($tunnelProcess.ExitCode -ne 0) {
        Write-Log "Tunnel service registration failed. Profile retained at $ConfigPath"
        if ($TranscriptStarted) { Stop-Transcript | Out-Null }
        Exit $tunnelProcess.ExitCode
    }

    if (-not (Wait-ForTunnelService -ServiceName $TunnelServiceName -TimeoutSeconds $TunnelServiceDetectionTimeoutSeconds)) {
        Write-Log "Tunnel service $TunnelServiceName was not detected within $TunnelServiceDetectionTimeoutSeconds seconds after registration."
        if ($TranscriptStarted) { Stop-Transcript | Out-Null }
        Exit 1
    }

    try {
        $tunnelService = Get-Service -Name $TunnelServiceName -ErrorAction Stop
        Set-Service -Name $TunnelServiceName -StartupType Automatic -ErrorAction Stop
        Write-Log "Set tunnel service $TunnelServiceName startup type to Automatic."

        if ($tunnelService.Status -ne 'Running') {
            Start-Service -Name $TunnelServiceName -ErrorAction Stop
            Write-Log "Started tunnel service $TunnelServiceName."
        }
    } catch {
        Write-Log "Failed to configure or start tunnel service ${TunnelServiceName}: $($_.Exception.Message)"
        if ($TranscriptStarted) { Stop-Transcript | Out-Null }
        Exit 1
    }

    Write-Log "Retaining tunnel configuration at $ConfigPath"
    
    Write-Log "WireGuard client and profile deployed successfully."
    if ($TranscriptStarted) { Stop-Transcript | Out-Null }
    Exit 0
} else {
    Write-Log "Critical Error: WireGuard installation failed. Executable not found at target path: $WireGuardExe"
    if ($TranscriptStarted) { Stop-Transcript | Out-Null }
    Exit 1
}
