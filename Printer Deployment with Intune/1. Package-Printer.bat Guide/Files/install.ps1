# --- Config ---

$PrinterName = "Printer 3. etg"
$PrinterIP = "192.168.1.15"
$PortName = "IP_$PrinterIP"

# Change these two values when you replace the driver package in UPD.
$DriverName = "HP Universal Printing PCL 6"
$INFFileName = "hpcu345u.inf"
$INFPath = "$PSScriptRoot\UPD\$INFFileName"
$PnPUtilPath = if (Test-Path "$env:windir\SysNative\pnputil.exe") {
	"$env:windir\SysNative\pnputil.exe"
} else {
	"$env:windir\System32\pnputil.exe"
}
$LogDirectory = Join-Path $env:ProgramData "PrinterDeployIntune"
$LogPath = Join-Path $LogDirectory "install.log"

$ErrorActionPreference = "Stop"

function Write-Log {
	param(
		[Parameter(Mandatory = $true)]
		[string]$Message
	)

	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$entry = "$timestamp $Message"
	Add-Content -Path $LogPath -Value $entry
	Write-Output $entry
}

if (-not (Test-Path $LogDirectory)) {
	New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
}

try {
	Write-Log "Starting printer install. PrinterName='$PrinterName' PrinterIP='$PrinterIP' DriverName='$DriverName' INF='$INFPath'"

	if (-not (Test-Path $INFPath)) {
		throw "Driver INF not found: $INFPath"
	}

	if (-not (Test-Path $PnPUtilPath)) {
		throw "pnputil.exe not found: $PnPUtilPath"
	}

	# --- Install printer ---

	Write-Log "Adding driver package with pnputil.exe at '$PnPUtilPath'"
	& $PnPUtilPath /add-driver $INFPath /install 2>&1 | ForEach-Object {
		Write-Log "pnputil: $_"
	}

	if ($LASTEXITCODE -ne 0) {
		throw "pnputil.exe failed with exit code $LASTEXITCODE"
	}

	if (Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue) {
		Write-Log "Printer driver already present: $DriverName"
	} else {
		Write-Log "Installing printer driver: $DriverName"
		Add-PrinterDriver -Name $DriverName
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













