# BGInfo Wallpaper for Intune

Corporate wallpaper with live system info (hostname, IPv4, serial) overlaid on the desktop.

## Change the background image

The background is downloaded at install from the URL in `$ImageUrl` (top of
`BGInfo\install.ps1`). To change the image, edit that URL to point at your bitmap.

A `BGInfo\background.bmp` bundled in the package is used only as a fallback if the
download fails (e.g. no network during Autopilot). Then repackage and re-upload to Intune.

## Do this in BGInfo before packaging (one-time)

Open `BGInfo\Company.bgi` in `Bginfo64.exe`, then:

1. **Background** → choose **Copy existing settings** (not a solid color, or the image
   won't show).
2. **File → Save**.

The IPv4/serial fields already read from `HKCU\Software\BGInfo`; `RefreshBGInfo.ps1` fills
those in and sets the background before each refresh.

## Package

```powershell
& ".\Microsoft-Win32-Content-Prep-Tool-master\IntuneWinAppUtil.exe" -c ".\BGInfo" -s "install.ps1" -o "." -q
```

Then upload the new `install.intunewin` to Intune. Repackaging locally does nothing until
you re-upload.

## Intune deploy settings

- **Install command:** `powershell.exe -ExecutionPolicy Bypass -File install.ps1`
- **Uninstall command:** `powershell.exe -ExecutionPolicy Bypass -File uninstall.ps1`
- **Install behavior:** System
- **Detection rule (File):** Rule type **File**, Path `C:\Program Files\BGInfo`,
  File `RefreshBGInfo.ps1`, Detection method **File or folder exists**.
