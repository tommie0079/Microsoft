$PrinterName = "Printer 3. etg"
if (Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue) {
    Write-Output "Printer Detected"
    Exit 0
} else {
    Exit 1
}
