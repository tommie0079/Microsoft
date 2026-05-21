param(
    [Parameter(Mandatory = $true)]
    [string]$PrinterIP,

    [string]$InstallScriptPath,
    [string]$UninstallScriptPath
)

if (-not $InstallScriptPath) {
    $InstallScriptPath = Join-Path $PSScriptRoot 'install.ps1'
}

if (-not $UninstallScriptPath) {
    $UninstallScriptPath = Join-Path $PSScriptRoot 'uninstall.ps1'
}

if (-not (Test-Path $InstallScriptPath)) {
    throw "install.ps1 not found: $InstallScriptPath"
}

if (-not (Test-Path $UninstallScriptPath)) {
    throw "uninstall.ps1 not found: $UninstallScriptPath"
}

function Replace-ScriptAssignment {
    param(
        [string]$Content,
        [string]$VariableName,
        [string]$Value
    )

    $assignmentPattern = '(?m)^\${0}\s*=\s*"[^"]*"\s*$' -f [regex]::Escape($VariableName)

    if (-not [regex]::IsMatch($Content, $assignmentPattern)) {
        throw "Expected `$${VariableName} assignment was not found."
    }

    return [regex]::Replace(
        $Content,
        $assignmentPattern,
        ('${0} = "{1}"' -f ('$' + $VariableName), $Value),
        1
    )
}

$installScriptContent = Get-Content -Path $InstallScriptPath -Raw -ErrorAction Stop
$updatedInstallContent = Replace-ScriptAssignment -Content $installScriptContent -VariableName 'PrinterIP' -Value $PrinterIP
Set-Content -Path $InstallScriptPath -Value $updatedInstallContent -Encoding UTF8

$uninstallScriptContent = Get-Content -Path $UninstallScriptPath -Raw -ErrorAction Stop
$updatedUninstallContent = Replace-ScriptAssignment -Content $uninstallScriptContent -VariableName 'PrinterIP' -Value $PrinterIP
Set-Content -Path $UninstallScriptPath -Value $updatedUninstallContent -Encoding UTF8

Write-Host 'Updated shared config:'
Write-Host ("PrinterIP = `"{0}`"" -f $PrinterIP)
