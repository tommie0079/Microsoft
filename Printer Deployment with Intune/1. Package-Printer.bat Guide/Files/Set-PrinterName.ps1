param(
    [Parameter(Mandatory = $true)]
    [string]$PrinterName,

    [string]$InstallScriptPath,
    [string]$UninstallScriptPath,
    [string]$DetectionScriptPath
)

if (-not $InstallScriptPath) {
    $InstallScriptPath = Join-Path $PSScriptRoot 'install.ps1'
}

if (-not $UninstallScriptPath) {
    $UninstallScriptPath = Join-Path $PSScriptRoot 'uninstall.ps1'
}

if (-not $DetectionScriptPath) {
    $DetectionScriptPath = Join-Path $PSScriptRoot 'detection.ps1'
}

if (-not (Test-Path $InstallScriptPath)) {
    throw "install.ps1 not found: $InstallScriptPath"
}

if (-not (Test-Path $UninstallScriptPath)) {
    throw "uninstall.ps1 not found: $UninstallScriptPath"
}

if (-not (Test-Path $DetectionScriptPath)) {
    throw "detection.ps1 not found: $DetectionScriptPath"
}

function Set-ScriptAssignment {
    param(
        [string]$Content,
        [string]$VariableName,
        [string]$Value
    )

    $assignmentPattern = '(?m)^\${0}\s*=\s*"[^"]*"\s*$' -f [regex]::Escape($VariableName)

    if (-not [regex]::IsMatch($Content, $assignmentPattern)) {
        throw "Expected `$$VariableName assignment was not found."
    }

    return [regex]::Replace(
        $Content,
        $assignmentPattern,
        ('${0} = "{1}"' -f ('$' + $VariableName), $Value),
        1
    )
}

$installScriptContent = Get-Content -Path $InstallScriptPath -Raw -ErrorAction Stop
$updatedInstallContent = Set-ScriptAssignment -Content $installScriptContent -VariableName 'PrinterName' -Value $PrinterName
Set-Content -Path $InstallScriptPath -Value $updatedInstallContent -Encoding UTF8

$uninstallScriptContent = Get-Content -Path $UninstallScriptPath -Raw -ErrorAction Stop
$updatedUninstallContent = Set-ScriptAssignment -Content $uninstallScriptContent -VariableName 'PrinterName' -Value $PrinterName
Set-Content -Path $UninstallScriptPath -Value $updatedUninstallContent -Encoding UTF8

$detectionScriptContent = Get-Content -Path $DetectionScriptPath -Raw -ErrorAction Stop
$updatedDetectionContent = Set-ScriptAssignment -Content $detectionScriptContent -VariableName 'PrinterName' -Value $PrinterName
Set-Content -Path $DetectionScriptPath -Value $updatedDetectionContent -Encoding UTF8

Write-Host 'Updated shared config:'
Write-Host ("PrinterName = `"{0}`"" -f $PrinterName)
