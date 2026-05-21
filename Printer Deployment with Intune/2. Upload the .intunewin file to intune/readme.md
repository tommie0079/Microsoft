
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


For detection rules, use a custom detection script and upload `detection.ps1` separately in Intune.
The `.intunewin` package also contains a copy of `detection.ps1`, but Intune does not use that copy automatically for detection.
Set `Run script as 32-bit process on 64-bit clients` to `No`.

## Assignments

Choose whether the printer should be:

- `Required`
- `Available` in Company Portal

In this example, the printer is configured as **Available** for all users.

<img width="582" height="596" alt="Uten navn" src="https://github.com/user-attachments/assets/ecfdef57-7c78-4163-abbf-b31bac6720a6" />

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

