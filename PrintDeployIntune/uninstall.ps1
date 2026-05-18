# --- Config ---

$PrinterName = "Printer på kontoret"
$PrinterIP = "192.168.1.52"
$PortName = "IP_$PrinterIP"

$DriverName = "Samsung Universal Print Driver 3"
$INFFileName = "us016.inf"
$INFPath =  "$PSScriptRoot\UPD\$INFFileName"

# Avinstaller printer og printerport
if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
    Remove-Printer -Name $PrinterName
}

if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
    Remove-PrinterPort -Name $PortName
}
