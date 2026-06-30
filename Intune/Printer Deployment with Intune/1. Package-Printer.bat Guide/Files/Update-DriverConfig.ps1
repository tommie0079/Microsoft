param(
    [string]$InstallScriptPath = "$PSScriptRoot\install.ps1",
    [string]$UninstallScriptPath = "$PSScriptRoot\uninstall.ps1",
    [string]$DetectionScriptPath = "$PSScriptRoot\detection.ps1",
    [string]$DriverFolderPath = "$PSScriptRoot\UPD",
    [int]$Selection
)

if (-not (Test-Path $InstallScriptPath)) {
    throw "install.ps1 not found: $InstallScriptPath"
}

if (-not (Test-Path $UninstallScriptPath)) {
    throw "uninstall.ps1 not found: $UninstallScriptPath"
}

if (-not (Test-Path $DetectionScriptPath)) {
    throw "detection.ps1 not found: $DetectionScriptPath"
}

if (-not (Test-Path $DriverFolderPath)) {
    throw "Driver folder not found: $DriverFolderPath"
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

function Update-PreferredDriverNames {
    param(
        [string]$Content,
        [string]$DriverName
    )

    $arrayPattern = '(?ms)^\$PreferredDriverNames\s*=\s*@\(\s*(?<Entries>.*?)\s*\)'

    if (-not [regex]::IsMatch($Content, $arrayPattern)) {
        return $null
    }

    $replacement = @(
        '$PreferredDriverNames = @('
        ('{0}"{1}"' -f "`t", 'HP LaserJet P4515 PCL6 Class Driver')
        ('{0}"{1}"' -f "`t", $DriverName)
        ')'
    ) -join [Environment]::NewLine

    return [regex]::Replace($Content, $arrayPattern, $replacement, 1)
}

function Get-ScriptAssignment {
    param(
        [string]$Content,
        [string]$VariableName
    )

    $assignmentMatch = [regex]::Match(
        $Content,
        ('(?m)^\${0}\s*=\s*"([^"]*)"\s*$' -f [regex]::Escape($VariableName))
    )

    if (-not $assignmentMatch.Success) {
        throw "Expected `$${VariableName} assignment was not found."
    }

    return $assignmentMatch.Groups[1].Value
}

$candidates = foreach ($infFile in Get-ChildItem -Path $DriverFolderPath -Filter '*.inf' -File) {
    $content = Get-Content -Path $infFile.FullName -Raw -ErrorAction Stop

    if ($content -notmatch '(?im)^Class\s*=\s*Printer\s*$') {
        continue
    }

    $driverNameMatches = [regex]::Matches($content, '(?m)^\s*"([^"]+)"\s*=')
    $driverNames = foreach ($driverNameMatch in $driverNameMatches) {
        $driverNameMatch.Groups[1].Value
    }

    foreach ($driverName in ($driverNames | Sort-Object -Unique)) {
        [pscustomobject]@{
            INFFileName = $infFile.Name
            DriverName = $driverName
        }
    }
}

if (-not $candidates) {
    throw "No printer driver candidates were found in $DriverFolderPath"
}

$selectedCandidate = $null

if ($candidates.Count -eq 1) {
    $selectedCandidate = $candidates[0]
} elseif ($PSBoundParameters.ContainsKey('Selection')) {
    if ($Selection -lt 1 -or $Selection -gt $candidates.Count) {
        throw "Selection must be between 1 and $($candidates.Count)"
    }

    $selectedCandidate = $candidates[$Selection - 1]
} else {
    Write-Host 'Possible driver candidates found in UPD:'

    for ($index = 0; $index -lt $candidates.Count; $index++) {
        $candidate = $candidates[$index]
        Write-Host ("[{0}] {1}  ->  {2}" -f ($index + 1), $candidate.INFFileName, $candidate.DriverName)
    }

    $selectionNumber = 0

    do {
        $selection = Read-Host 'Select the correct driver number'
    } until ([int]::TryParse($selection, [ref]$selectionNumber) -and $selectionNumber -ge 1 -and $selectionNumber -le $candidates.Count)

    $selectedCandidate = $candidates[$selectionNumber - 1]
}

$installScriptContent = Get-Content -Path $InstallScriptPath -Raw -ErrorAction Stop
$updatedContent = $installScriptContent

$preferredDriverContent = Update-PreferredDriverNames -Content $updatedContent -DriverName $selectedCandidate.DriverName

if ($null -ne $preferredDriverContent) {
    $updatedContent = $preferredDriverContent
} else {
    $updatedContent = Replace-ScriptAssignment -Content $updatedContent -VariableName 'DriverName' -Value $selectedCandidate.DriverName
    $updatedContent = Replace-ScriptAssignment -Content $updatedContent -VariableName 'INFFileName' -Value $selectedCandidate.INFFileName
}

Set-Content -Path $InstallScriptPath -Value $updatedContent -Encoding UTF8

$printerName = Get-ScriptAssignment -Content $updatedContent -VariableName 'PrinterName'
$printerIP = Get-ScriptAssignment -Content $updatedContent -VariableName 'PrinterIP'

$uninstallScriptContent = Get-Content -Path $UninstallScriptPath -Raw -ErrorAction Stop
$updatedUninstallContent = $uninstallScriptContent
$updatedUninstallContent = Replace-ScriptAssignment -Content $updatedUninstallContent -VariableName 'PrinterName' -Value $printerName
$updatedUninstallContent = Replace-ScriptAssignment -Content $updatedUninstallContent -VariableName 'PrinterIP' -Value $printerIP
Set-Content -Path $UninstallScriptPath -Value $updatedUninstallContent -Encoding UTF8

$detectionScriptContent = Get-Content -Path $DetectionScriptPath -Raw -ErrorAction Stop
$updatedDetectionContent = Replace-ScriptAssignment -Content $detectionScriptContent -VariableName 'PrinterName' -Value $printerName
Set-Content -Path $DetectionScriptPath -Value $updatedDetectionContent -Encoding UTF8

Write-Host 'Updated install.ps1 with:'
if ($null -ne $preferredDriverContent) {
    Write-Host ("PreferredDriverNames fallback = `"{0}`"" -f $selectedCandidate.DriverName)
} else {
    Write-Host ("DriverName = `"{0}`"" -f $selectedCandidate.DriverName)
    Write-Host ("INFFileName = `"{0}`"" -f $selectedCandidate.INFFileName)
}
Write-Host 'Synced shared config:'
Write-Host ("PrinterName = `"{0}`"" -f $printerName)
Write-Host ("PrinterIP = `"{0}`"" -f $printerIP)
