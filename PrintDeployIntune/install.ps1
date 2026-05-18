# --- Config ---

$PrinterName = "Printer pa kontoret"
$PrinterIP = "192.168.1.52"
$PortName = "IP_$PrinterIP"

# Change these two values when you replace the driver package in UPD.
$DriverName = "HP Universal Printing PS"
$INFFileName = "hpcu355z.inf"
$INFPath = "$PSScriptRoot\UPD\$INFFileName"

if (-not (Test-Path $INFPath)) {
	throw "Driver INF not found: $INFPath"
}

# --- Install printer ---

# Installer driver og printer port
pnputil.exe /add-driver $INFPath /install
Add-PrinterDriver -Name $DriverName
Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP

# Installer printer
Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName

