# Printer Deployment with Intune

This repository contains a simple workflow for packaging and deploying a network printer with Microsoft Intune.

## Preparation

1. Connect the printer to the correct network, for example an IoT network or another dedicated network for this type of device.
2. Reserve a static IP address for the printer in UniFi so the address does not change.
3. Optional: Add the printer manually on a Windows client to confirm that printing works over the network.
4. Download the printer driver for later use.
	In many cases, HP `.exe` driver packages can be extracted with 7-Zip instead of being installed directly. The folder you need is typically:

	```text
	SamsungUniversalDriver\Printer\UPD
	```

	Copy the entire `UPD` folder into this project.

## Project Structure

Create a packaging folder that contains:

- `UPD/`
- `install.ps1`
- `uninstall.ps1`
- `detection.ps1`

Then adapt the PowerShell scripts to match your printer and environment.

## Package the App

Package the application as an `.intunewin` file by using Microsoft Win32 Content Prep Tool.

## Create the App in Intune

1. Go to https://intune.microsoft.com.
2. Open **Apps** and select **Windows**.
3. Click **Create** and choose **Windows app (Win32)**.
4. Upload the `.intunewin` file you created in the previous step.
5. Add a clear name, description, and icon so the app looks good in Company Portal.

Use the following commands:

```powershell
powershell.exe -ExecutionPolicy Bypass -File "install.ps1"
```

```powershell
powershell.exe -ExecutionPolicy Bypass -File "uninstall.ps1"
```

For detection rules, use a custom detection script and upload `detection.ps1`.

## Assignments

Choose whether the printer should be:

- `Required`
- `Available` in Company Portal

In this example, the printer is configured as **Available** for all users.
 
