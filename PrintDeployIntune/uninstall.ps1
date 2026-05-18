# --- Config ---

$PrinterName = "Printer pa kontoret"
$PrinterIP = "192.168.1.52"
$PortName = "IP_$PrinterIP"

# Avinstaller printer og printerport
if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
    Remove-Printer -Name $PrinterName
}

if (Get-PrinterPort -Name $PortName -ErrorAction SilentlyContinue) {
    Remove-PrinterPort -Name $PortName
}
