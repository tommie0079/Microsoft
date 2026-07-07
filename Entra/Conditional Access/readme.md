# Conditional Access – Step-by-Step Guide

> **Reference:** [How to Set Up Conditional Access in Microsoft 365 (Step-by-Step) – YouTube](https://www.youtube.com/watch?v=5oMaZink7kc)
>
> Requires Microsoft 365 Business Premium (Entra ID P1). Policy 5 and Access Reviews require Entra ID P2/E5.

## 0. Preparation
1. Sign in at **admin.microsoft.com** > **Admin centers** > **Identity** (Entra admin center).
2. Go to **Entra ID** > **Conditional Access** > **Policies**.
3. Use the naming standard: **Who – What – Condition** (e.g. `All users - All apps - Require MFA`).
4. Set up break glass accounts (see next section) and exclude them from ALL policies.

## 0.1 Break glass accounts (emergency access)
> Recommended: **passwordless with FIDO2 security key** (e.g. YubiKey 5 NFC) — this is Microsoft's current guidance and is phishing-resistant.
<img width="564" height="503" alt="image" src="https://github.com/user-attachments/assets/53373099-1d7b-41cf-8de9-c25b10afe4f5" />

- [ ] Create **two** break glass accounts (cloud-only, Global Administrator, `@tenant.onmicrosoft.com`).
- [ ] Register a **dedicated YubiKey 5 NFC** for each account (passwordless FIDO2 sign-in).
- [ ] Store the keys in **separate secure locations** (e.g. safe at the office + safe off-site).
- [ ] Add both accounts to the `CA-BreakGlass` group and **exclude it from all Conditional Access policies**.
- [ ] Set up **alerts** on any sign-in from these accounts (sign-in logs / Log Analytics).
- [ ] **Test** the accounts regularly (e.g. quarterly) so you know they work.

> ⚠️ Never rely on a *single* key-only account — a lost key = total lockout. That's why you have two accounts with two keys in different locations.

## 1. Create a "Modern MFA" authentication strength
1. Go to **Authentication methods** > **Authentication strengths** > **New authentication strength**.
2. Name: `Modern MFA`. Use this checklist when selecting methods:

   **Select (✅):**
   - [ ] Windows Hello for Business
   - [ ] Passkeys (FIDO2)
   - [ ] Microsoft Authenticator (phone sign-in / passwordless)
   - [ ] Temporary Access Pass (one-time use)
   - [ ] Password + Microsoft Authenticator (Push)

   **Do NOT select (❌):**
   - [ ] ~~SMS~~
   - [ ] ~~Voice call~~
   - [ ] ~~Email OTP~~

   > **What is "Password + Microsoft Authenticator (Push)"?** The user signs in with their password first, then gets a **push notification** in the Authenticator app on their phone and must approve it (typically by tapping a matching number shown on the sign-in screen). Two factors: something you *know* (password) + something you *have* (the phone). Much stronger than SMS since codes can't be intercepted via SIM swapping, but weaker than passkeys/FIDO2 because a user can still be tricked into approving a fraudulent push (MFA fatigue attacks).

3. Click **Create**.

## 2. Five baseline policies (New policy for each)

### Policy 1: `All users - All apps - Require strong MFA`
- **Users**: All users (exclude break glass/admin).
- **Target resources**: All resources.
- **Grant**: Require authentication strength > `Modern MFA`.
- Set to **On** > **Create**.

### Policy 2: `All users - Legacy authentication clients - Block access`
- **Users**: All users (exclude break glass).
- **Conditions** > **Client apps**: select the legacy authentication clients.
- **Grant**: **Block access** > On > Create.

### Policy 3: `All users - Device registration - Require MFA`
- **Users**: All users (exclude break glass).
- **Target resources** > **User actions**: *Register or join devices*.
- **Grant**: Require authentication strength > `Modern MFA` > On > Create.

### Policy 4: `All users - Device code flow - Block access`
- **Users**: All users (exclude break glass).
- **Target resources**: All resources.
- **Conditions** > **Authentication flows**: enable, select *Device code flow*.
- **Grant**: **Block access** > On > Create.

### Policy 5 (requires Entra ID P2): `All users - All apps - High sign-in risk - Block access`
- **Users**: All users (exclude break glass).
- **Target resources**: All cloud apps.
- **Conditions** > **Sign-in risk**: High (optionally Medium).
- **Grant**: **Block access** > On > Create.

### Policy 6 (optional): `All users - All apps - Non-allowed countries - Block access`
1. First create a named location: **Conditional Access** > **Named locations** > **+ Countries location** > name it `Allowed countries` > select **Norway** (and any other countries you operate from) > Create.
2. New policy:
   - **Users**: All users (exclude break glass).
   - **Target resources**: All resources.
   - **Conditions** > **Locations**: Include *Any location*, **Exclude** `Allowed countries`.
   - **Grant**: **Block access**.
3. Test in **Report-only** first, then set to **On**.

> ⚠️ Notes: Attackers can bypass this with a VPN, so keep MFA as the main control. Plan for travelling staff (add countries temporarily, or use a TAP/exclusion group with access reviews). Location is based on IP, so unknown/unmapped IPs may behave unexpectedly.

## 3. Create the persona groups

### Static groups (simple start)
1. Go to **Entra ID** > **Groups** > **All groups** > **New group**.
2. Group type: **Security**. Membership type: **Assigned**.
3. Create: `CA-Admins`, `CA-Staff`, `CA-Guests`, `CA-BreakGlass`.
4. Add members manually to each group.

### Dynamic groups (recommended when you scale — requires Entra ID P1)
Members are added/removed **automatically** based on a rule, so no one is forgotten.
1. **New group** > Group type: **Security** > Membership type: **Dynamic User**.
2. Click **Add dynamic query** and build a rule, e.g.:

| Group | Example rule |
|---|---|
| `CA-Staff` | `(user.accountEnabled -eq true) and (user.userType -eq "Member")` |
| `CA-Guests` | `(user.userType -eq "Guest")` |
| `CA-Admins` | Keep **static** – admin roles should be assigned deliberately |
| `CA-BreakGlass` | Keep **static** – only the two emergency accounts |

3. Click **Validate Rules** to test against real users, then **Save** > **Create**.

> ⚠️ Tip: exclude break glass accounts from the staff rule if needed, e.g. `... and (user.displayName -notContains "BreakGlass")`. Dynamic membership can take a few minutes to update after a change.

## 4. Personas (policies)

Target the groups from section 3 in these policies. Remember: when multiple policies apply to a user, the **strictest wins**. Test everything in **Report-only** before switching to **On**.

### 4.1 `Admins - All apps - Require phishing-resistant MFA`
1. **Users**: `CA-Admins`, exclude `CA-BreakGlass`.
2. **Target resources**: All resources.
3. **Grant**: Require authentication strength > **Phishing-resistant MFA**.
4. **Report-only** > **Create**.

### 4.2 `Admins - All apps - Require company-owned compliant device`
1. **Users**: `CA-Admins`, exclude `CA-BreakGlass`.
2. **Target resources**: All resources.
3. **Conditions** > **Filter for devices**:
   - Configure: **Yes**.
   - Select: **Include filtered devices in policy**.
   - Rule: Property `deviceOwnership` – Operator `Equals` – Value `Company` (rule syntax: `device.deviceOwnership -eq "Company"`).
   - Click **Done**.
4. **Grant**: **Grant access** + check **Require device to be marked as compliant** > Select.
5. **Report-only** > **Create**.

### 4.3 `Staff - All apps - Require company-owned compliant device`
Same steps as 4.2, but target **`CA-Staff`** instead of `CA-Admins`.

> Note (from the video): smartphones are left out of the staff policy for now — handle mobile devices with a separate policy later.

### 4.4 `Guests - All apps - Block mobile and desktop apps`
1. **Users**: `CA-Guests`.
2. **Target resources**: All cloud apps.
3. **Conditions** > **Client apps**: switch on, **uncheck Browser** (keep mobile apps and desktop clients checked).
4. **Grant**: **Block access**.
5. **Report-only** > **Create**.

## 5. Exceptions (without permanent exclusions)
- **Temporary Access Pass (TAP)**: Verify the user > **Users** > select user > **Authentication methods** > **Add** > *Temporary Access Pass* > set **One-time use** > give the code to the user.
- **Access Reviews** (requires P2): **ID Governance** > **Access reviews** > New review of your exclusion groups, monthly, with justification required – so no one stays excluded forever.
