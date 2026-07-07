# Auto Time Zone – Intune Remediation

Intune Proactive Remediation that sets the time zone to `W. Europe Standard Time` (Oslo), enables automatic time zone updates, and ensures the Windows Time service (W32Time) is running.

## Files

- `detection.ps1` – Checks that the time zone is `W. Europe Standard Time`, `tzautoupdate` Start = 3, and W32Time is set to Automatic. Exits 0 (compliant) or 1 (not compliant).
- `Enable-AutoTime.ps1` – Remediation script. Sets the time zone to `W. Europe Standard Time`, enables automatic time zone detection, configures/starts W32Time, and resyncs the clock.

## What does the script do?

The remediation script does two things:

1. **Sets the time zone explicitly** to `W. Europe Standard Time` (Oslo) – a guaranteed fix that does not depend on location services.
2. **Enables automatic time zone detection** (`tzautoupdate`), so Windows keeps the zone correct going forward using the device's location (via location services / Wi-Fi geolocation).

It also ensures the Windows Time service (W32Time) is running and resyncs the clock.

- **Caveat:** if location services are disabled on the device, the automatic detection won't update the zone on location changes – but the explicit `Set-TimeZone` still guarantees the correct zone for devices in Norway.

## Deployment settings (Intune)

- Run this script using the logged-on credentials: **No** (run in system context)
- Run script in 64-bit PowerShell: **Yes**

## Triggering the script immediately on a client PC

You can't truly "push" it instantly from Intune, but you can trigger it much faster than waiting for the schedule (remediations normally run per their assigned schedule, and new assignments can take up to ~8 hours to reach the client):

### Fastest option — Run on-demand (from Intune)

1. Intune portal → **Devices** → select the device → **…** (or the device overview page)
2. Choose **Run remediation** and pick your remediation script package. This runs it within minutes.

### From the client PC

- **Settings → Accounts → Access work or school → Info → Sync** — forces a policy sync.
- Or restart the Intune Management Extension service, which forces it to re-check for scripts/remediations immediately. In an elevated PowerShell:

  ```powershell
  Restart-Service -Name IntuneManagementExtension
  ```

### For testing without Intune at all

Run the scripts locally in an elevated 64-bit PowerShell to verify the logic works before waiting on Intune:

```powershell
.\detection.ps1        # should output "Not compliant" + exit 1
.\Enable-AutoTime.ps1  # applies fix
.\detection.ps1        # should now output "Compliant" + exit 0
```

The on-demand **Run remediation** option is the closest thing to an immediate push.

## Verifying the result on a client PC

Run this on the client after remediation:

```powershell
Get-TimeZone | Select-Object Id, DisplayName
(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate').Start   # should be 3
Get-Service W32Time | Select-Object Status, StartType                             # Running / Automatic
w32tm /query /status                                                              # check "Last Successful Sync Time"
```

Expected time zone Id: `W. Europe Standard Time`.
