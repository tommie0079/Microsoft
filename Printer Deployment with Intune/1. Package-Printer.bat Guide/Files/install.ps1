# --- Config ---

$PrinterName = "printertest2"
$PrinterIP = "printerrrrrr"
$PortName = "IP_$PrinterIP"

# Prefer the built-in class driver and only use UPD if it is already present locally.
$PreferredDriverNames = @(
	"HP LaserJet P4515 PCL6 Class Driver",
	"HP Universal Printing PCL 6"
)
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
		throw "None of the preferred printer drivers are installed: $($PreferredDriverNames -join ', '). Install one of them on the target device first."
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





















