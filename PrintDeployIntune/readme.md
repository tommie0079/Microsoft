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
3. Run `Update-DriverConfig.ps1`.
4. Confirm that `install.ps1`, `uninstall.ps1`, and `detection.ps1` now have the expected values.
5. Package the app as `.intunewin` and upload it to Intune.

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


## Create the App in Intune

1. Go to https://intune.microsoft.com.
2. Open **Apps** and select **Windows**.
3. Click **Create** and choose **Windows app (Win32)**.
4. Upload the `.intunewin` file you created in the previous step.
5. Add a clear name, description, and icon so the app looks good in Company Portal.
<img width="542" height="605" alt="Uten navn" src="https://github.com/user-attachments/assets/a32507e5-b5b4-4486-a8f6-fe76688bf694" />


Use the following commands:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "install.ps1"
```

```powershell
powershell.exe -ExecutionPolicy Bypass -File "uninstall.ps1"
```
<img width="582" height="599" alt="Uten navn" src="https://github.com/user-attachments/assets/ac7d3799-cdb4-4ee8-bd0d-839f130e7304" />


For detection rules, use a custom detection script and upload `detection.ps1` and leave the default at No

## Assignments

Choose whether the printer should be:

- `Required`
- `Available` in Company Portal

In this example, the printer is configured as **Available** for all users.

<img width="582" height="596" alt="Uten navn" src="https://github.com/user-attachments/assets/ecfdef57-7c78-4163-abbf-b31bac6720a6" />


