# Package-Printer.bat guide
Testet with:

* HP LaserJet Enterprise MFP M577
* HP LaserJet P4515x

This guide is only for using `Package-Printer.bat`.
<img width="1473" height="756" alt="Uten navn" src="https://github.com/user-attachments/assets/d4ebccbd-137b-4bd6-a52a-b3da0c3fe77e" />

This guide is only for using `Package-Printer.bat`.

## What this does

`Package-Printer.bat` helps you prepare and package the printer deployment into an `.intunewin` file.

It can:

1. Update driver config
2. Set printer IP
3. Set printer name
4. Install `IntuneWinAppUtil.exe`
5. Create `.intunewin`
6. Open the `Output` folder

## Files you need first

Make sure this folder contains at least:

```text
PrintDeployIntune\
|-- Package-Printer.bat
|-- Set-PrinterIP.ps1
|-- Set-PrinterName.ps1
|-- Update-DriverConfig.ps1
|-- install.ps1
|-- uninstall.ps1
|-- detection.ps1
+-- UPD\
    +-- ...driver files
```

Important:

- Put the extracted printer driver files inside `UPD`.
- Edit `PrinterName` and `PrinterIP` in `install.ps1` before you start.

## How to run it

Open the project folder and run:

```bat
Package-Printer.bat
```

You will get this menu:

```text
1. Update driver config
2. Set printer IP
3. Set printer name
4. Install IntuneWinAppUtil.exe
5. Create .intunewin
6. Open Output folder
0. Exit
```

## Recommended order

### Step 1: Update driver config

Choose option `1`.

This runs `Update-DriverConfig.ps1`, which:

- scans the `UPD` folder for printer `.inf` files
- lets you choose the correct driver if more than one is found
- updates `DriverName` and `INFFileName` in `install.ps1`
- syncs `PrinterName` and `PrinterIP` to the other scripts

Make sure the chosen `.inf` supports the Windows architecture on the target devices. For example, an `NTARM64`-only HP INF will not install on normal Windows x64 clients.

### Step 2: Set printer IP

Choose option `2`.

This updates `PrinterIP` in:

- `install.ps1`
- `uninstall.ps1`

Use this if the printer gets a different static IP or if you want to avoid editing the script manually.

### Step 3: Set printer name

Choose option `3`.

This updates `PrinterName` in:

- `install.ps1`
- `uninstall.ps1`
- `detection.ps1`

Use this if you want a different printer display name without editing the scripts manually.

### Step 4: Install IntuneWinAppUtil.exe

Choose option `4`.

This downloads `IntuneWinAppUtil.exe` into the same folder as `Package-Printer.bat`.

Official source:

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

### Step 5: Create the package

Choose option `5`.

This will:

- create a temporary `PackageSource` folder
- copy `install.ps1`, `uninstall.ps1`, `detection.ps1`, and `UPD` into it
- create the `Output` folder automatically if needed
- generate the `.intunewin` package

When it succeeds, the `.intunewin` file is saved in:

```text
Output\
```

### Step 6: Open the Output folder

Choose option `6`.

This opens the `Output` folder in Explorer.
If the folder does not exist yet, the batch file creates it automatically.

## Notes

- You do not need to create the `Output` folder manually.
- `Output` is created automatically by option `5` or option `6`.
- If option `5` says `IntuneWinAppUtil.exe` was not found, run option `4` first.

## After packaging

Upload the generated `.intunewin` file to Intune as a Win32 app.

Use these commands in Intune:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "install.ps1"
```

```powershell
powershell.exe -ExecutionPolicy Bypass -File "uninstall.ps1"
```

For detection, upload `detection.ps1` as a custom detection script.
You must upload it separately in Intune even though the `.intunewin` package also contains a copy.
Intune does not automatically use the packaged copy for the detection rule.
Leave `Run script as 32-bit process on 64-bit clients` set to `No`.

## Troubleshoot

If Intune shows **Installation failed**, check these logs on the client:

- `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
- `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AgentExecutor.log`
- `C:\ProgramData\PrinterDeployIntune\install.log`

What they are used for:

- `IntuneManagementExtension.log` shows app download, install command execution, return codes, and detection results.
- `AgentExecutor.log` shows PowerShell script execution details and error output from `install.ps1` and `detection.ps1`.
- `install.log` is written by this package and shows each install step, including `pnputil`, `Add-PrinterDriver`, `Add-PrinterPort`, and `Add-Printer`.

If the issue looks printer-related, also check **Event Viewer**:

- `Applications and Services Logs > Microsoft > Windows > PrintService > Operational`

If install succeeds but detection fails, Intune can still report the app as failed. In that case, confirm that `detection.ps1` is uploaded separately in Intune and that `PrinterName` matches exactly across `install.ps1`, `uninstall.ps1`, and `detection.ps1`.
