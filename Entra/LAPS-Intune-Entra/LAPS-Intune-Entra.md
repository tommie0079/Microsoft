# Set up Windows LAPS in Intune / Entra

Windows LAPS (Local Administrator Password Solution) automatically manages and backs up the local administrator account password on Entra ID joined devices.

## Prerequisites

- Devices running Windows 10 20H2 or later (with the April 2023 or later update), or Windows 11.
- Devices are **Microsoft Entra joined** or **Microsoft Entra hybrid joined**.
- Devices are enrolled in **Microsoft Intune**.

### Required admin roles

Different tasks need different roles. Grant the least privilege required:

| Task | Sufficient role |
|---|---|
| Enable LAPS in Entra (Device settings) | **Global Administrator** |
| Create / assign the Intune LAPS policy | **Intune Administrator** |
| Recover (read) the rotated LAPS password | **Cloud Device Administrator**, Intune Administrator, Security Administrator, or Global Administrator |

> **Cloud Device Administrator** is *not* required to configure LAPS — it is the least-privilege role for helpdesk staff who only need to **read** passwords. The person configuring the policy needs **Intune Administrator** (plus **Global Administrator** to flip the Entra device setting).

## Step 1: Enable LAPS in Microsoft Entra

1. Go to the [Microsoft Entra admin center](https://entra.microsoft.com).
2. Navigate to **Identity** > **Devices** > **Device settings**.
3. Under **Local administrator password solution (LAPS)**, set **Enable Microsoft Entra Local Administrator Password Solution (LAPS)** to **Yes**.
4. Click **Save**.

## Step 2: Create the LAPS policy in Intune

1. Go to the [Microsoft Intune admin center](https://intune.microsoft.com).
2. Navigate to **Endpoint security** > **Account protection**.
3. Click **+ Create Policy**.
   - **Platform:** Windows
   - **Profile:** Local admin password solution (Windows LAPS)
4. Click **Create**.
5. On the **Basics** tab, enter a **Name** (e.g. `LAPS Policy`) and optional description, then click **Next**.

## Step 3: Configure settings

Recommended settings:

| Setting | Recommended value |
|---|---|
| **Backup Directory** | Backup the password to Microsoft Entra ID only |
| **Password Age Days** | 30 |
| **Administrator Account Name** | (blank to use built-in, or specify a custom account) |
| **Password Complexity** | Large letters + small letters + numbers + special characters |
| **Password Length** | 14 or higher |
| **Post Authentication Actions** | Reset the password and logoff the managed account |
| **Post Authentication Reset Delay** | 24 (hours) |

Click **Next** when done.

### Which account should LAPS manage?

- **Custom account (recommended):** Set **Administrator Account Name** to a *new* dedicated account name. LAPS creates and enables this account automatically — you do **not** need to touch the built-in Administrator, and it stays disabled for better security.
- **Built-in Administrator:** Leave **Administrator Account Name** blank. The built-in `Administrator` account is **disabled by default**, so LAPS will rotate its password but you won't be able to log in until the account is enabled (see Step 4).

## Step 4: (Only for the built-in account) Enable the Administrator account

Skip this step if you used a custom account name in Step 3.

Do **not** use Local Security Policy (`secpol.msc`) on Entra-joined devices — they are managed by Intune, not local policy. Enable the account through Intune instead:

1. Create a **Settings Catalog** policy in Intune:
   1. Sign in to the [Microsoft Intune admin center](https://intune.microsoft.com).
   2. Go to **Devices** > **Configuration** (under *Manage devices*).
   3. Click **+ Create** > **New Policy**.
   4. Set **Platform** to *Windows 10 and later* and **Profile type** to *Settings catalog*, then click **Create**.
   5. On the **Basics** tab, enter a **Name** (e.g. `Enable Built-in Administrator`) and optional description, then click **Next**.
   6. On the **Configuration settings** tab, click **+ Add settings**.
   7. In the settings picker, search for **Administrator account status** and select the category **Local Policies Security Options**.
   8. Tick **Accounts Enable Administrator Account Status**, then close the picker.
   9. Toggle the setting to **Enabled**.
2. Alternatively, deploy a PowerShell / remediation script: `Enable-LocalUser -Name "Administrator"`.
3. Assign the policy to the same device groups as the LAPS policy.

## Step 5: Assign the policy

1. On the **Assignments** tab, add the device or user groups that should receive the policy.
2. Click **Next**, review on the **Review + create** tab, then click **Create**.

## Step 6: Verify

1. Wait for devices to sync (or force a sync from the device or Intune).
2. In the [Microsoft Intune admin center](https://intune.microsoft.com), go to **Devices** > select a device > **Local admin password**.
3. Click **Show local administrator password** to view the current managed password.

> You can also view it in the Entra admin center under **Devices** > select a device > **Local administrator password recovery**.

## Notes

- Passwords are stored securely in Entra ID and rotated automatically based on **Password Age Days**.
- Viewing a password is logged in the **audit logs** for accountability.
- If using a custom admin account name, LAPS creates and enables it automatically — no separate step needed.
- Microsoft's recommendation: leave the built-in Administrator **disabled** and let LAPS manage a dedicated custom local admin account.
