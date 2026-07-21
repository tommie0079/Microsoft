# MeshCentral – Intune + Docker (Test Setup)

Short guide for hosting **MeshCentral** in Docker and deploying the **MeshAgent** to a
Windows PC through **Microsoft Intune**. This is a **test setup** used to try out remote
control of a single PC — not a production deployment.

## Overview

```
Server (Docker)  ──►  MeshCentral web + agent connections
Client (Intune)  ──►  MeshAgent installed via Win32 app
```

- **Server:** MeshCentral running in Docker.
- **Client:** MeshAgent packaged as a Win32 app and pushed from Intune.
- **Goal:** Log into the MeshCentral web UI and remotely control the test PC.

## 1. Host the server (Docker)

1. Open `Server/Docker/`.
2. Edit `config.json` and set your server IP/hostname in `cert` and `allowedOrigin`
   (the sample uses `192.168.1.45`).
3. Start the container:

   ```bash
   docker compose up -d
   ```

4. Open `https://<server-ip>` in a browser and create the **first account**
   (this becomes the admin).

### Ports

| Port     | Purpose                                        |
| -------- | ---------------------------------------------- |
| 443/TCP  | Main HTTPS web interface and agent connections |
| 80/TCP   | HTTP → HTTPS redirect (optional)               |
| 4433/TCP | Intel AMT / CIRA management (optional)         |

### Lock down sign-ups (after creating the admin)

Once your admin account exists, block self-registration:

1. In `config.json` set `"newAccounts": false`.
2. Re-apply on the host:

   ```bash
   docker compose up -d --force-recreate
   ```

Existing accounts keep working; you can still add users from the web UI as admin.

## 2. Deploy the agent (Intune)

1. In MeshCentral, create a **device group** and download the Windows agent
   (e.g. `meshagent64-<group>.exe`).
2. Package it as a Win32 app with the
   **Microsoft Win32 Content Prep Tool** (see `Intune/`) to produce `install.intunewin`.
3. Configure the Win32 app in Intune:

   - **Install command:**

     ```cmd
     meshagent64.exe -fullinstall
     ```

   - **Uninstall command:**

     ```cmd
     "C:\Program Files\Mesh Agent\MeshAgent.exe" -uninstall
     ```

   - **Detection rule:** file exists →
     `C:\Program Files\Mesh Agent\MeshAgent.exe`

4. **Assignment:** assign the app to **All Users** (assign to *users*, not devices).

## 3. Test

- Wait for the agent to install, then check the device appears in the MeshCentral group.
- Open the device and start a **remote desktop** session to confirm it works.

## Notes

> Test environment only. Uses a self-signed cert and a local IP — do not expose it
> to the internet without proper certificates and hardening.
