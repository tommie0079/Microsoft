$PrinterName = "Printer på kontoret"
if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
    Write-Output "Printer Detected"
    Exit 0
} else {
    Exit 1
}