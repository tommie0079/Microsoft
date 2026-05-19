# Printer Deployment with Intune

This repository contains a simple workflow for packaging and deploying a network printer with Microsoft Intune.

## Preparation

1. Connect the printer to the correct network, for example an IoT network or another dedicated network for this type of device.
2. Reserve a static IP address for the printer in UniFi so the address does not change.
3. Optional: Add the printer manually on a Windows client to confirm that printing works over the network.
4. Download the printer driver for later use.
	In many cases, vendor `.exe` driver packages can be extracted with 7-Zip instead of being installed directly. The folder you need is typically a `UPD` folder inside the extracted package, for example:

	```text
	SomeDriverPackage\Printer\UPD
	```

	Copy the entire `UPD` folder into this project.
	You do not need to open `Install.exe` manually if the extracted driver files are already inside `UPD`.

## Project Structure

Create a packaging folder that contains:

- `UPD/`
- `install.ps1`
- `uninstall.ps1`
- `detection.ps1`

Example structure:

```text
PrintDeployIntune\
|-- Package-Printer.bat
|-- Update-DriverConfig.ps1
|-- install.ps1
|-- uninstall.ps1
|-- detection.ps1
|-- readme.md
+-- UPD\
	|-- hpcu355z.inf
	|-- hpcu355z.cat
	|-- hpcu355sSPS.xml
	+-- ...more driver files
```

Then adapt the PowerShell scripts to match your printer and environment.

If you want help updating `install.ps1` for a new driver package, you can run:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\Update-DriverConfig.ps1"
```

The helper script scans the `UPD` folder for printer `.inf` files, lets you choose a detected driver if there is more than one, and then updates `DriverName` and `INFFileName` in `install.ps1` automatically.
If you already know which option number you want, you can run it non-interactively, for example `powershell.exe -ExecutionPolicy Bypass -File ".\Update-DriverConfig.ps1" -Selection 1`.
It also copies `PrinterName` and `PrinterIP` from `install.ps1` into `uninstall.ps1`, and copies `PrinterName` into `detection.ps1`, so the scripts stay aligned.

The current example in this repository is set up for the HP driver package already placed in `UPD`:

- `DriverName = "HP Universal Printing PS"`
- `INFFileName = "hpcu355z.inf"`

Before packaging, update these values in `install.ps1`:

- `PrinterName` in `install.ps1`
- `PrinterIP` in `install.ps1`

Then run `Update-DriverConfig.ps1` so those values are synced to the other scripts.

## How to change the driver next time

If you replace the contents of `UPD` with another driver package, update `install.ps1` like this:

1. Find the correct `.inf` file inside `UPD`.
2. Open that `.inf` file in a text editor.
3. Look near the top for the printer driver name, usually written inside quotes, for example:

```text
"HP Universal Printing PS" = ...
```

4. Set `INFFileName` in `install.ps1` to that `.inf` file name.
5. Set `DriverName` in `install.ps1` to the quoted driver name from the `.inf` file.

Example:

```powershell
$DriverName = "HP Universal Printing PS"
$INFFileName = "hpcu355z.inf"
```

Keep `PrinterName` identical in all three scripts, or detection and uninstall will not match the installed printer. If you use `Update-DriverConfig.ps1`, it will sync that for you.

You can either do those steps manually, or run `Update-DriverConfig.ps1` to update `install.ps1` and sync the other scripts for you.

## Recommended workflow

1. Extract the printer driver package and copy its `UPD` folder into this project.
2. Edit `PrinterName` and `PrinterIP` in `install.ps1`.
3. Run `Package-Printer.bat` and choose option `1` to update the driver config.
4. If needed, use option `2` to download `IntuneWinAppUtil.exe`.
5. Use option `3` to create the `.intunewin` package.
6. Use option `4` if you want to open the `Output` folder directly.
7. Upload the generated `.intunewin` file to Intune.

## Quick start with Package-Printer.bat

The easiest way to use this repository is to run:

```bat
Package-Printer.bat
```

It gives you these options:

1. `Update driver config`
2. `Install IntuneWinAppUtil.exe`
3. `Create .intunewin`
4. `Open Output folder`

This is the recommended workflow for normal use. The manual steps below are still available if you want to run each step yourself.

## Package the App

Package the application as an `.intunewin` file by using Microsoft Win32 Content Prep Tool (`IntuneWinAppUtil.exe`).
The recommended source is the official Microsoft GitHub repository:
https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool

1. Download `IntuneWinAppUtil.exe` from the official Microsoft repository, preferably from the latest release:
	https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool/releases
2. Create a staging folder that contains the files you want inside the package. For this project, the folder should contain at least:

```text
PackageSource\
	install.ps1
	uninstall.ps1
	detection.ps1
	UPD\
```

3. Copy the updated scripts and the full `UPD` folder into that staging folder.
4. Run the packaging command:

```powershell
.\IntuneWinAppUtil.exe -c ".\PackageSource" -s "install.ps1" -o ".\Output"
```

Explanation:

- `-c` is the source folder that will be packed.
- `-s` is the setup file Intune runs during install. In this project that must be `install.ps1`.
- `-o` is the folder where the generated `.intunewin` file will be saved.

The tool will create an `.intunewin` file in the `Output` folder. Upload that file to Intune.

Example if you package directly from this repository:

```powershell
.\IntuneWinAppUtil.exe -c "." -s "install.ps1" -o ".\Output"
```

That works because `install.ps1` and the `UPD` folder are already in the repository root.
If you use the repository root as the source, all files in the folder are included in the package, not only `install.ps1`.



