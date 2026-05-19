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


