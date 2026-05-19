# Package-Printer.bat Guide
<img width="1478" height="753" alt="image" src="https://github.com/user-attachments/assets/e10fb394-11b5-477b-97df-12cbb8d922ec" />

This guide is only for using `Package-Printer.bat`.

## What this does

`Package-Printer.bat` helps you prepare and package the printer deployment into an `.intunewin` file.

It can:

1. Update driver config
2. Install `IntuneWinAppUtil.exe`
3. Create `.intunewin`
4. Open the `Output` folder

## Files you need first

Make sure this folder contains at least:

```text
PrintDeployIntune\
|-- Package-Printer.bat
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
2. Install IntuneWinAppUtil.exe
3. Create .intunewin
4. Open Output folder
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

### Step 2: Install IntuneWinAppUtil.exe

Choose option `2`.

This downloads `IntuneWinAppUtil.exe` into the same folder as `Package-Printer.bat`.

Official source:

https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

### Step 3: Create the package

Choose option `3`.

This will:

- create a temporary `PackageSource` folder
- copy `install.ps1`, `uninstall.ps1`, `detection.ps1`, and `UPD` into it
- create the `Output` folder automatically if needed
- generate the `.intunewin` package

When it succeeds, the `.intunewin` file is saved in:

```text
Output\
```

### Step 4: Open the Output folder

Choose option `4`.

This opens the `Output` folder in Explorer.
If the folder does not exist yet, the batch file creates it automatically.

## Notes

- You do not need to create the `Output` folder manually.
- `Output` is created automatically by option `3` or option `4`.
- If option `3` says `IntuneWinAppUtil.exe` was not found, run option `2` first.

## After packaging

Upload the generated `.intunewin` file to Intune as a Win32 app.

Use these commands in Intune:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "install.ps1"
```

```powershell
powershell.exe -ExecutionPolicy Bypass -File "uninstall.ps1"
```

For detection, upload `detection.ps1` as a custom detection script and leave `Run script as 32-bit process on 64-bit clients` set to `No`.
