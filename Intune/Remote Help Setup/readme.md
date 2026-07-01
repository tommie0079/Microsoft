# Remote Help Setup

## In admin.microsoft.com

1. Search for **Microsoft Intune Remote Help** in the Marketplace
2. Click **Start free trial**
3. Edit "Sold to", do not check this box:
<img width="544" height="275" alt="image" src="https://github.com/user-attachments/assets/f33422be-0678-4a6e-9f43-b874258c7b17" />

### Assign Remote Help license

- Assign a license to both the user and the admin account that provides help.
- Publish the app to device groups, not user groups.
- If an apprentice wants to offer help, assign the **Help Desk Operator** role.

## In intune.microsoft.com

1. Go to **Tenant administration**
2. **Remote Help**
3. **Settings -> Enable Remote Help** → Enable

## Roll out the Remote Help app to clients

1. Download the script from GitHub to package `remotehelp.exe` into an `.intunewin` file
2. Download the Remote Help installer from Microsoft:
   https://aka.ms/downloadremotehelp
3. In Intune, create a **Win32 app**
4. Upload the `.intunewin` file

### Install

```
remotehelpinstaller.exe /quiet acceptTerms=1
```

### Uninstall

```
remotehelpinstaller.exe /uninstall /quiet acceptTerms=1
```

## Detection

You can't skip that page, but you also do not need a detection script. Choose **Manually configure detection rules**.

Then add a file-based detection rule for Remote Help:

- **Rule type:** File
- **Path:** `C:\Program Files\Remote Help`
- **File or folder:** `RemoteHelp.exe`
- **Detection method:** String (version)
- **Operator:** Greater than or equal to
- **Value:** `5.2.1037.0`
- **Associated with a 32-bit app on 64-bit clients:** No

## Start a remote session

> **IMPORTANT!** This must be done from a PC in the same domain, not from another PC connected to a different domain!
<img width="2143" height="1092" alt="image" src="https://github.com/user-attachments/assets/526a26c5-66eb-4f9e-af1a-7a13770180d8" />


Make sure the user is logged in to the Company Portal.

Getting a blank screen? Install Remote Help on the helper PC as well.

## Additional task

NOK 35.60 per month for a Remote Help license. Is it cheaper to use TeamViewer, for example, or RustDesk?

Line-of-business app -> upload the `.msi` file for RustDesk
