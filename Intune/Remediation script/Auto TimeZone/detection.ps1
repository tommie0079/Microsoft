$ExpectedTimeZone = "W. Europe Standard Time"

try {
    $currentTz = (Get-TimeZone).Id
    $tzStart = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -ErrorAction Stop).Start
    $w32Time = Get-Service -Name W32Time -ErrorAction Stop

    if ($currentTz -eq $ExpectedTimeZone -and $tzStart -eq 3 -and $w32Time.StartType -eq 'Automatic') {
        Write-Output "Compliant: TimeZone=$currentTz"
        exit 0
    }
    else {
        Write-Output "Not compliant: TimeZone=$currentTz, tzautoupdate Start=$tzStart, W32Time StartType=$($w32Time.StartType)"
        exit 1
    }
}
catch {
    Write-Output "Not compliant: $($_.Exception.Message)"
    exit 1
}