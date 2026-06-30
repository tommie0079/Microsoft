# --- Config ---

$PrinterName = "VGS printer test 29-06"
$PrinterIP = "192.168.1.138"
$PortName = "IP_$PrinterIP"

# Prefer the built-in class driver and fall back to the driver bundled in the package.
$PreferredDriverNames = @(
	"HP LaserJet P4515 PCL6 Class Driver"
	"HP Universal Printing PCL 6"
)

# Driver bundled inside the package (UPD folder shipped in the .intunewin).
$BundledDriverModelName = "HP Universal Printing PCL 6"
$BundledDriverInfName = "hpcu360y.inf"
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

function Resolve-PrinterDriverName {
	param(
		[Parameter(Mandatory = $true)]
		[string[]]$CandidateNames
	)

	foreach ($candidateName in $CandidateNames) {
		if (Get-PrinterDriver -Name $candidateName -ErrorAction SilentlyContinue) {
			return $candidateName
		}
	}

	return $null
}

function Install-BundledPrinterDriver {
	param(
		[Parameter(Mandatory = $true)]
		[string]$InfName,
		[Parameter(Mandatory = $true)]
		[string]$ModelName
	)

	$infPath = Join-Path $PSScriptRoot (Join-Path "UPD" $InfName)
	if (-not (Test-Path $infPath)) {
		throw "Bundled driver INF not found in package: $infPath"
	}

	Write-Log "Staging bundled driver into the driver store: $infPath"
	$pnputilOutput = & pnputil.exe /add-driver "$infPath" /install 2>&1
	$pnputilExit = $LASTEXITCODE
	foreach ($line in $pnputilOutput) {
		Write-Log "pnputil: $line"
	}

	# pnputil returns 0 on success and 3010 when a reboot is required; both mean the driver was staged.
	if ($pnputilExit -ne 0 -and $pnputilExit -ne 3010) {
		throw "pnputil failed to stage bundled driver '$InfName' (exit code $pnputilExit)."
	}

	if (-not (Get-PrinterDriver -Name $ModelName -ErrorAction SilentlyContinue)) {
		Write-Log "Registering printer driver: $ModelName"
		Add-PrinterDriver -Name $ModelName
	}

	if (-not (Get-PrinterDriver -Name $ModelName -ErrorAction SilentlyContinue)) {
		throw "Driver '$ModelName' was not available after staging bundled INF '$InfName'."
	}

	return $ModelName
}

if (-not (Test-Path $LogDirectory)) {
	New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

if (-not (Test-Path $LegacyLogDirectory)) {
	New-Item -ItemType Directory -Path $LegacyLogDirectory -Force | Out-Null
}

try {
	Write-Log "Starting printer install. PrinterName='$PrinterName' PrinterIP='$PrinterIP' PreferredDrivers='$($PreferredDriverNames -join ", ")'"

	$DriverName = Resolve-PrinterDriverName -CandidateNames $PreferredDriverNames
	if (-not $DriverName) {
		Write-Log "No preferred driver present. Installing bundled driver '$BundledDriverModelName' from package."
		$DriverName = Install-BundledPrinterDriver -InfName $BundledDriverInfName -ModelName $BundledDriverModelName
	}

	# --- Install printer ---
	Write-Log "Using installed printer driver: $DriverName"

	if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
		Write-Log "Printer port already present: $PortName"
	} else {
		Write-Log "Creating printer port: $PortName"
		Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP
	}

	$existingPrinter = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
	if ($existingPrinter) {
		Write-Log "Printer already present: $PrinterName"
		if ($existingPrinter.PortName -ne $PortName) {
			Write-Log "Updating printer port from '$($existingPrinter.PortName)' to '$PortName'"
			Set-Printer -Name $PrinterName -PortName $PortName
		} else {
			Write-Log "Printer already uses target port: $PortName"
		}
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


























