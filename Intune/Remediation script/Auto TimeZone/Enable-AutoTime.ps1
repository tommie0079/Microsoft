$ExpectedTimeZone = "W. Europe Standard Time"

try {
    # Set the time zone explicitly (guaranteed fix, does not depend on location services)
    Set-TimeZone -Id $ExpectedTimeZone -ErrorAction Stop

    # Enable automatic time zone updates for future location changes
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -Value 3 -Type DWord -ErrorAction Stop

    # Ensure Windows Time service is running and set to start automatically
    Set-Service -Name W32Time -StartupType Automatic -ErrorAction Stop
    Start-Service -Name W32Time -ErrorAction Stop

    # Resync the clock (non-fatal if it fails, e.g. no network)
    w32tm /resync /nowait | Out-Null

    Write-Output "Remediation completed: TimeZone set to $ExpectedTimeZone"
    exit 0
}
catch {
    Write-Output "Remediation failed: $($_.Exception.Message)"
    exit 1
}