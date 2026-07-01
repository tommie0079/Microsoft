# WireGuard VPN – Automated Deployment via Intune

A simple corporate VPN connection through WireGuard. The server runs as a Docker
service on Ubuntu, and the Windows client is automatically deployed and configured
through Microsoft Intune (Win32 app), where it installs and runs as a service.

---

## Overview

| Component | Description |
| --- | --- |
| **Server** | WireGuard running in Docker on Ubuntu |
| **Client config** | `company-vpn.conf` – packaged with the installer |
| **Installer** | `install.ps1` – installs the WireGuard client and the VPN tunnel service |
| **Detection** | `detection.ps1` – tells Intune whether the app is installed |
| **Package** | `install.intunewin` – the Win32 app uploaded to Intune |

---

## Phase 1: Set up the WireGuard server (Ubuntu)

### 1. Install Docker

Install Docker Engine on Ubuntu by following the official guide:

➡️ <https://docs.docker.com/engine/install/ubuntu/>

### 2. Create the `docker-compose.yml`

Create the file `srv/docker-compose.yml` with the following content:

```yaml
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - SERVERURL=192.168.1.38       # <-- change to your server's public IP / hostname
      - SERVERPORT=51820
      - PEERS=corporatevpn
      - PEERDNS=10.13.13.1
      - INTERNAL_SUBNET=10.13.13.0
      - ALLOWEDIPS=0.0.0.0/0
      - PERSISTENTKEEPALIVE_PEERS=all
      - LOG_CONFS=true
    volumes:
      - ./wireguard/config:/config
      - /lib/modules:/lib/modules:ro
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
```

Start the container:

```bash
sudo docker compose up -d
```

### 3. Extract the peer private key

Once the container is running, read the private key generated for the peer:

```bash
sudo docker exec wireguard cat /config/peer_corporatevpn/privatekey-peer_corporatevpn
```

### 4. Update `company-vpn.conf`

Open `company-vpn.conf` and:

- Replace **`PrivateKey`** with the key extracted in the previous step.
- Replace the IP address in **`Endpoint`** with the IP/hostname your server is
  running on (must match `SERVERURL` in the compose file).

```ini
[Interface]
Address = 10.13.13.2
PrivateKey = <PASTE-EXTRACTED-PRIVATE-KEY-HERE>
ListenPort = 51820
DNS = 10.13.13.1

[Peer]
PublicKey = 4MtyWRjg76NrX+7WCdOYnaULfwwDierOWY1Bhj4j1g4=
PresharedKey = WDXZ5LvUiDSG3CRaVNxZj3LqmnhrUxUMp+iDjXBREbM=
Endpoint = 192.168.1.38:51820   # <-- change to your server's IP / hostname
AllowedIPs = 0.0.0.0/0
```

> The server should now be up and accepting connections. ✅

---

## Phase 2: Package the client for Intune

### 1. Download the packaging tool

Download **IntuneWinAppUtil.exe** from Microsoft's
[Microsoft-Win32-Content-Prep-Tool](https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool).

### 2. Create the `.intunewin` file

Run `IntuneWinAppUtil.exe` and point it at this folder. Answer the prompts:

```text
Please specify the source folder: C:\WireGuardDeploy
Please specify the setup file: install.ps1
Please specify the output folder: C:\WireGuardDeploy
Do you want to specify catalog folder (Y/N)? N
```

This produces `install.intunewin`.

---

## Phase 3: Publish in Microsoft Intune

Now head over to your [Microsoft Intune Admin Center](https://intune.microsoft.com/).

### 1. Add the app

- Go to **Apps > All apps > Add**.
- Select **Windows app (Win32)** from the *App type* dropdown and click **Select**.
- Click **Select app package file**, upload your newly created `install.intunewin`
  file, and click **OK**.

### 2. App information

| Field | Value |
| --- | --- |
| **Name** | WireGuard VPN (All-in-One) |
| **Description** | Installs WireGuard client and configures the Corporate VPN Profile. |
| **Publisher** | WireGuard |

### 3. Program settings

Configure how Intune commands the installation on target devices:

| Setting | Value |
| --- | --- |
| **Install command** | `%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -File install.ps1` |
| **Uninstall command** | `"C:\Program Files\WireGuard\wireguard.exe" /uninstalltunnelservice CorporateVPN` |
| **Install behavior** | System *(Crucial: must run as administrator)* |
| **Device restart behavior** | Determine behavior based on return codes |

### 4. Requirements

- **Operating system architecture:** x64
- **Minimum operating system:** Windows 10 1607

### 5. Detection rules

- Choose **Use a custom detection script** and upload `detection.ps1`.

---

## Troubleshooting

If the connection does not work, check the firewall on the server.

### Install the firewall

```bash
sudo apt update
sudo apt install ufw -y
```

### Allow WireGuard

```bash
sudo ufw allow 51820/udp
sudo ufw enable
```

### Enable SSH (so you don't lock yourself out)

```bash
sudo ufw allow ssh
sudo ufw allow 22/tcp
```
