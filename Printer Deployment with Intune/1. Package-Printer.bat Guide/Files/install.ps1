# --- Config ---

$PrinterName = "printer igor"
$PrinterIP = "192.168.1.138"
$PortName = "IP_$PrinterIP"

# Change these two values when you replace the driver package in UPD.
$DriverName = "HP Universal Printing PCL 6"
$INFFileName = "hpcu360u.inf"
$INFPath = "$PSScriptRoot\UPD\$INFFileName"
$PnPUtilPath = if (Test-Path "$env:windir\SysNative\pnputil.exe") {
	"$env:windir\SysNative\pnputil.exe"
} else {
	"$env:windir\System32\pnputil.exe"
}
$LogDirectory = Join-Path $env:ProgramData "PrinterDeployIntune"
$LogPath = Join-Path $LogDirectory "install.log"
$LegacyLogDirectory = Join-Path $env:ProgramData "PrinterDeployment"
$LegacyLogPath = Join-Path $LegacyLogDirectory "install.log"

$ErrorActionPreference = "Stop"

function Write-Log {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Message
	)

	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$entry = "$timestamp $Message"
	Add-Content -Path $LogPath -Value $entry
	if ($LegacyLogPath -ne $LogPath) {
		Add-Content -Path $LegacyLogPath -Value $entry
	}
	Write-Output $entry
}

function Get-OSArchitecture {
	if ($env:PROCESSOR_ARCHITEW6432) {
		return $env:PROCESSOR_ARCHITEW6432.ToUpperInvariant()
	}

	return $env:PROCESSOR_ARCHITECTURE.ToUpperInvariant()
}

function Get-InfSupportedArchitectures {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	$architectures = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
	$sectionHeaders = Select-String -Path $Path -Pattern '^\[(?<Section>[^\]]+)\]$'

	foreach ($header in $sectionHeaders) {
		$sectionName = $header.Matches[0].Groups['Section'].Value

		if ($sectionName -match '(^|\.)(NTamd64)(\.|$)') {
			[void]$architectures.Add('AMD64')
		}

		if ($sectionName -match '(^|\.)(NTARM64)(\.|$)') {
			[void]$architectures.Add('ARM64')
		}

		if ($sectionName -match '(^|\.)(NTx86)(\.|$)') {
			[void]$architectures.Add('X86')
		}
	}

	return @($architectures)
}

if (-not (Test-Path $LogDirectory)) {
	New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

if (-not (Test-Path $LegacyLogDirectory)) {
	New-Item -ItemType Directory -Path $LegacyLogDirectory -Force | Out-Null
}

try {
	Write-Log "Starting printer install. PrinterName='$PrinterName' PrinterIP='$PrinterIP' DriverName='$DriverName' INF='$INFPath'"

	if (-not (Test-Path $INFPath)) {
		throw "Driver INF not found: $INFPath"
	}

	if (-not (Test-Path $PnPUtilPath)) {
		throw "pnputil.exe not found: $PnPUtilPath"
	}

	$currentArchitecture = Get-OSArchitecture
	$supportedArchitectures = Get-InfSupportedArchitectures -Path $INFPath
	if ($supportedArchitectures.Count -gt 0 -and $supportedArchitectures -notcontains $currentArchitecture) {
		throw "Driver INF '$INFFileName' supports [$($supportedArchitectures -join ', ')] but this OS is $currentArchitecture. Use a matching driver package for this device architecture."
	}

	# --- Install printer ---

	Write-Log "Adding driver package with pnputil.exe at '$PnPUtilPath'"
	$pnputilOutput = & $PnPUtilPath /add-driver $INFPath /install 2>&1
	$pnputilOutput | ForEach-Object {
		Write-Log "pnputil: $_"
	}

	if ($LASTEXITCODE -ne 0) {
		throw "pnputil.exe failed with exit code $LASTEXITCODE"
	}

	$publishedNameMatch = $pnputilOutput | Select-String -Pattern 'Published Name:\s*(?<PublishedName>\S+)' | Select-Object -First 1
	$driverStoreInfPath = if ($publishedNameMatch) {
		$publishedNameMatch.Matches[0].Groups['PublishedName'].Value
	} else {
		$INFFileName
	}

	if (Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue) {
		Write-Log "Printer driver already present: $DriverName"
	} else {
		Write-Log "Installing printer driver: $DriverName from '$driverStoreInfPath'"
		Add-PrinterDriver -Name $DriverName -InfPath $driverStoreInfPath
	}

	if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
		Write-Log "Printer port already present: $PortName"
	} else {
		Write-Log "Creating printer port: $PortName"
		Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
	}

	$existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
	if ($existingPrinter) {
		Write-Log "Printer already present: $PrinterName"
	} else {
		Write-Log "Creating printer: $PrinterName"
		Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName
	}

	Write-Log "Printer install completed successfully"
	exit 0
} catch {
	Write-Log "ERROR: $($_.Exception.Message)"
	throw
}

















