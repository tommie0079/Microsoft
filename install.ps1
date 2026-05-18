# --- Config ---

$PrinterName = "Printer på kontoret"
$PrinterIP = "192.168.1.52"
$PortName = "IP_$PrinterIP"

$DriverName = "Samsung Universal Print Driver 3"
$INFFileName = "us016.inf"
$INFPath =  "$PSScriptRoot\UPD\$INFFileName"

# --- Install printer ---

# Installer driver og printer port
pnputil.exe /add-driver $INFPath /install
Add-PrinterDriver -Name $DriverName
Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP

# Installer printer
Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName