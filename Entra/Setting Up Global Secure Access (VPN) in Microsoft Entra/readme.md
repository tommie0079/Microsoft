# Setting Up Global Secure Access (VPN) in Microsoft Entra

A short step-by-step guide to enable and configure **Global Secure Access (GSA)** in Microsoft Entra. GSA is Microsoft's Security Service Edge (SSE) solution that secures access to internet, Microsoft 365, and private resources through the Entra Global Secure Access Client (the "VPN").

## Prerequisites

- A **Microsoft Entra ID P1** license (and **Microsoft Entra Internet Access / Private Access** licenses for those features).
- A **Global Secure Access Administrator** or **Global Administrator** role.
- Windows 10/11 or Android devices that are **Entra joined** or **Entra hybrid joined**.
- Devices must be able to install the **Global Secure Access Client**.

## Step 1 — Activate Global Secure Access

1. Sign in to the [Microsoft Entra admin center](https://entra.microsoft.com).
2. Go to **Global Secure Access** > **Get started**.
3. Select **Activate Global Secure Access** to enable the service in your tenant.
<img width="1627" height="785" alt="image" src="https://github.com/user-attachments/assets/2d0a6219-5650-4ac4-af9b-bb636dc713a1" />



## Step 2 — Enable Traffic Forwarding Profiles

1. Navigate to **Global Secure Access** > **Connect** > **Traffic forwarding**.
2. Enable the profile(s) you need:
   - **Microsoft 365 traffic** – secures and optimizes Microsoft 365 access.
   - **Private access traffic** – routes traffic to your internal/private apps.
   - **Internet access traffic** – secures general internet/web traffic.

## Step 3 — Install the Global Secure Access Client

1. Go to **Global Secure Access** > **Connect** > **Client download**.
2. Download the **Global Secure Access Client** installer.
3. Deploy it to user devices manually or via **Microsoft Intune** / your management tool.
4. After install, the client signs in with the user's Entra credentials and connects automatically.

## Step 4 — Configure Private Access (optional)

For securing internal apps without a traditional VPN:

1. Go to **Global Secure Access** > **Applications** > **Enterprise applications**.
2. Select **New application** and create a **Private Access** app.
3. Install the **Private Network Connector** on a server inside your network.
4. Define the app segments (IP addresses, FQDNs, and ports) users should reach.
5. Assign users or groups who need access.

## Step 5 — Apply Conditional Access Policies

1. Go to **Entra ID** > **Conditional Access**.
2. Create a policy targeting the **Global Secure Access** apps.
3. Require controls such as **MFA**, **compliant device**, or **sign-in risk** conditions.
4. Use the **Universal Conditional Access** feature to enforce policies across GSA traffic.

## Step 6 — Verify and Monitor

1. On a client device, confirm the **Global Secure Access Client** shows **Connected**.
2. In the Entra admin center, go to **Global Secure Access** > **Monitor** > **Traffic logs** to verify traffic is flowing.
3. Use the **Dashboard** to review usage, devices, and applied policies.

## Tips

- Roll out to a **pilot group** first before tenant-wide deployment.
- Combine **Internet Access** + **Private Access** for full Zero Trust coverage.
- Keep the client updated by managing it through **Intune**.

---

*Reference: [Microsoft Global Secure Access documentation](https://learn.microsoft.com/entra/global-secure-access/)*
