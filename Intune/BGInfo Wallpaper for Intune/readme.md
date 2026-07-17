# BGInfo Wallpaper for Intune

Deploys [Sysinternals BGInfo](https://learn.microsoft.com/sysinternals/downloads/bginfo)
as an Intune Win32 app: a corporate wallpaper with live system info (hostname, IPv4, etc.)
overlaid on the desktop. Runs in the logged‑on user's session and refreshes at every logon.

## Prerequisites

Download and place these into the repo before packaging:

1. **BGInfo** – https://download.sysinternals.com/files/BGInfo.zip
   Extract and copy `Bginfo64.exe` into the `BGInfo\` folder.
2. **Intune Content Prep Tool** – https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool
   Provides `IntuneWinAppUtil.exe` (used to build `install.intunewin`).

## Repo layout

| File | Purpose |
| --- | --- |
| `BGInfo\Bginfo64.exe` | BGInfo executable (download separately) |
| `BGInfo\Company.bgi` | BGInfo layout (fields + background) |
| `BGInfo\RefreshBGInfo.ps1` | Writes IPv4 + serial number to `HKCU\Software\BGInfo`, then runs BGInfo |
| `BGInfo\install.ps1` | Installer: copies files, sets Run key, runs in user session |
| `BGInfo\uninstall.ps1` | Removes files, Run key, task, registry, wallpaper |
| `install.intunewin` | Packaged app to upload to Intune |

## Configure `Company.bgi` (one‑time, BGInfo GUI)

The IPv4 and serial-number fields read a **registry value** (VBScript is deprecated and
isn't stored in the `.bgi`). `RefreshBGInfo.ps1` writes the values; BGInfo just reads them.

1. Run `Bginfo64.exe`, open `Company.bgi`.
2. (Optional) **Background** → set your corporate wallpaper bitmap.
3. **Custom → New**: Identifier `IPv4`, *A registry value*, path
   `HKEY_CURRENT_USER\Software\BGInfo\IPv4`. Add it to the layout.
4. **Custom → New**: Identifier `SerialNumber`, *A registry value*, path
   `HKEY_CURRENT_USER\Software\BGInfo\SerialNumber`. Add it to the layout.
5. **File → Save**.

Test locally: set the value, then open the config —

```powershell
& ".\BGInfo\RefreshBGInfo.ps1"   # writes HKCU\Software\BGInfo\IPv4 (needs Bginfo64.exe path adjusted for local runs)
.\BGInfo\Bginfo64.exe .\BGInfo\Company.bgi /nolicprompt
```

## Package

```powershell
& ".\Microsoft-Win32-Content-Prep-Tool-master\IntuneWinAppUtil.exe" -c ".\BGInfo" -s "install.ps1" -o "." -q
```

## Deploy in Intune (Win32 app)

- **Install command:** `powershell.exe -ExecutionPolicy Bypass -File install.ps1`
- **Uninstall command:** `powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1`
- **Install behavior:** System
- **Detection rule (File):** path `C:\Program Files\BGInfo`, file `RefreshBGInfo.ps1`,
  *File or folder exists*. (Detecting this file ensures package updates actually reinstall.)

Upload the new `install.intunewin` whenever you change anything — repackaging locally does
not update Intune until you re‑upload.

## Notes

- **Wallpaper policy conflicts:** an enforced wallpaper (Intune PersonalizationCSP or a GPO)
  overrides BGInfo. Either remove that policy, or set the corporate image inside
  `Company.bgi` and don't force a separate wallpaper.
- **Updates not applying?** The detection rule reports "installed" so the installer won't
  re‑run. Uninstall first (or delete `C:\Program Files\BGInfo` + the `BGInfo` Run key), then
  reinstall.
