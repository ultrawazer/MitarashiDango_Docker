# Dango Docker (Optimized for Unraid)

[![Build and Publish Docker Image](https://github.com/ultrawazer/Dando_Docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/ultrawazer/Dando_Docker/actions/workflows/docker-publish.yml)

Docker container packaging and Unraid template for [Dango](https://github.com/ultrawazer/dango) — a lightweight, local-first anime media client and tracker designed for performance, privacy, and personal library management.

---

## Features

- **Node.js 22 Runtime**: Leverages Node's native built-in SQLite engine (`node:sqlite`) for low memory and zero native compilation overhead.
- **Unraid-Native Permissions**: Dynamic `PUID` and `PGID` mapping (defaults to Unraid's `nobody:users` `99:100`) via `su-exec` to prevent permission lockouts on your cache drives or appdata share.
- **Persistent Appdata**: Mounts `/config` (typically `/mnt/user/appdata/dango`) where SQLite databases (`anime.db`), WAL files, sync manifests, and `.env` are safely preserved.
- **Graceful Shutdown**: Direct `SIGTERM` signal propagation ensures SQLite WAL checkpoints complete before container termination, preventing database corruption during Unraid reboot or container updates.
- **Pre-installed Rclone**: Ready out-of-the-box for Dango's built-in Rclone cloud sync provider.
- **Multi-Architecture**: Supports both `linux/amd64` (Intel/AMD x86_64) and `linux/arm64` (ARM devices / Raspberry Pi).

---

## Quick Start on Unraid

### Option A: Install via Unraid Template (Recommended)

1. Open your Unraid WebGUI and navigate to the **Docker** tab.
2. If using Unraid Community Applications or custom templates, copy [`dango.xml`](dango.xml) to your Unraid flash drive:
   ```bash
   /boot/config/plugins/dockerMan/templates-user/my-dango.xml
   ```
   *Or paste the template URL directly into Docker template repositories:*
   ```text
   https://raw.githubusercontent.com/ultrawazer/Dando_Docker/main/dango.xml
   ```
3. Click **Add Container** and select the **dango** template from the dropdown.
4. Verify the prefilled settings:
   - **Repository**: `ghcr.io/ultrawazer/dango:latest`
   - **WebUI Port**: `3000`
   - **Appdata Storage**: `/mnt/user/appdata/dango` &rarr; `/config`
   - **PUID**: `99`
   - **PGID**: `100`
5. Click **Apply**. Once downloaded, click the container icon and choose **WebUI** to launch Dango!

---

### Option B: Add Manually in Unraid WebGUI

If you are adding the container manually through the Unraid WebGUI:

1. Go to **Docker** &rarr; click **Add Container**.
2. Fill in the following fields:
   - **Name**: `dango`
   - **Repository**: `ghcr.io/ultrawazer/dango:latest`
   - **Network Type**: `Bridge`
   - **WebUI**: `http://[IP]:[PORT:3000]/`
   - **Icon URL**: `https://raw.githubusercontent.com/ultrawazer/dango/main/client/public/logo.png`
3. Click **Add another Path, Port, Variable, label or device**:
   - **Port**:
     - Name: `WebUI`
     - Container Port: `3000`
     - Host Port: `3000` (or any available port on your Unraid host)
     - Connection Type: `TCP`
   - **Path**:
     - Name: `Appdata`
     - Container Path: `/config`
     - Host Path: `/mnt/user/appdata/dango`
     - Access Mode: `Read/Write`
   - **Variable 1 (PUID)**:
     - Name: `PUID`
     - Key: `PUID`
     - Value: `99`
   - **Variable 2 (PGID)**:
     - Name: `PGID`
     - Key: `PGID`
     - Value: `100`
   - **Variable 3 (Timezone)**:
     - Name: `Timezone`
     - Key: `TZ`
     - Value: `America/New_York` (adjust to your timezone)
4. Click **Apply**.

---

## Docker CLI

To run Dango using the Docker CLI on any Linux host or Unraid terminal:

```bash
docker run -d \
  --name dango \
  --restart unless-stopped \
  -p 3000:3000 \
  -e PUID=99 \
  -e PGID=100 \
  -e UMASK=022 \
  -e TZ=UTC \
  -v /mnt/user/appdata/dango:/config \
  ghcr.io/ultrawazer/dango:latest
```

---

## Docker Compose

Save the following as `docker-compose.yml`:

```yaml
services:
  dango:
    image: ghcr.io/ultrawazer/dango:latest
    container_name: dango
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - PUID=99
      - PGID=100
      - UMASK=022
      - TZ=UTC
    volumes:
      - /mnt/user/appdata/dango:/config
```

Run:
```bash
docker compose up -d
```

---

## Environment Variables & Configuration

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `PUID` | `99` | User ID for file ownership (`99` is `nobody` on Unraid). |
| `PGID` | `100` | Group ID for file ownership (`100` is `users` on Unraid). |
| `UMASK` | `022` | File creation mask for newly written files. |
| `TZ` | `UTC` | Timezone for logging and schedule tracking (e.g., `America/New_York`, `Europe/London`). |
| `PORT` | `3000` | Internal container listening port. |
| `XDG_DATA_HOME` | `/config` | Dango base data root. Application data is placed in `/config/dango/`. |

---

## Directory Structure in Appdata

When mounted to `/mnt/user/appdata/dango`, Dango creates the following structure:

```text
/mnt/user/appdata/dango/
└── dango/
    ├── anime.db           # Main SQLite database (watchlist, user library)
    ├── anime.db-wal       # SQLite Write-Ahead Log
    ├── anime.db-shm       # SQLite Shared Memory
    ├── sync_manifest.json # Cloud sync manifest & change tracking
    ├── google_tokens.json # OAuth tokens (if Google Drive sync is enabled)
    └── .env               # Local configuration and API tokens
```

---

## Building Locally

To build the Docker image locally from source:

```bash
# Clone this packaging repo
git clone https://github.com/ultrawazer/Dando_Docker.git
cd Dando_Docker

# Build image (clones and compiles ultrawazer/dango)
docker build -t dango:local .

# To build a specific branch or release tag:
docker build --build-arg BRANCH=main -t dango:local .
```

---
