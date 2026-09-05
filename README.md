# Dango Docker (Optimized for Unraid)

[![Build and Publish Docker Image](https://github.com/ultrawazer/Dando_Docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/ultrawazer/Dando_Docker/actions/workflows/docker-publish.yml)

Docker container packaging and Unraid template for [Dango](https://github.com/ultrawazer/dango) — a lightweight, local-first anime media client and tracker designed for performance, privacy, and personal library management.

---

## Features

- **Node.js 22 Runtime**: Leverages Node's native built-in SQLite engine (`node:sqlite`) for low memory and zero native compilation overhead.
- **Shoko Server Integration**: Stream local MKV and MP4 files directly from your Unraid server via Shoko's Virtual File System (VFS).
- **Hardware Acceleration**: Built-in FFmpeg with Intel QuickSync (`vaapi`) and AMD GPU support via `/dev/dri` for instant, zero-CPU stream-copy remuxing (MKV &rarr; fMP4).
- **Dual Audio & Subtitle Switching**: Dynamic stream mapping for dual-audio anime and in-player subtitle track selection.
- **Two-Way Watch Scrobbling**: Automatically syncs watched episode status back to your Shoko Server.
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
   - **Transcode Scratch Path**: `/tmp/dango-transcode` &rarr; `/transcode`
   - **Shoko Server URL**: `http://192.168.1.100` (or your Unraid host IP)
   - **Shoko Server Port**: `8111`
   - **GPU Device**: `/dev/dri` &rarr; `/dev/dri`
   - **PUID / PGID**: `99` / `100`
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
   - **Extra Parameters**: `--device /dev/dri`
3. Add the following paths and variables:
   - **Port**: Container Port `3000` &rarr; Host Port `3000`
   - **Path (Appdata)**: `/config` &rarr; `/mnt/user/appdata/dango`
   - **Path (Transcode)**: `/transcode` &rarr; `/tmp/dango-transcode` (RAM or cache)
   - **Device (GPU)**: `/dev/dri` &rarr; `/dev/dri`
   - **Variable (PUID)**: `99`
   - **Variable (PGID)**: `100`
   - **Variable (TZ)**: `UTC`
   - **Variable (SHOKO_URL)**: `http://192.168.1.100`
   - **Variable (SHOKO_PORT)**: `8111`
   - **Variable (HW_ACCEL)**: `auto`
4. Click **Apply**.

---

## Docker CLI

To run Dango using the Docker CLI on any Linux host or Unraid terminal:

```bash
docker run -d \
  --name dango \
  --restart unless-stopped \
  -p 3000:3000 \
  --device /dev/dri:/dev/dri \
  -e PUID=99 \
  -e PGID=100 \
  -e UMASK=022 \
  -e TZ=UTC \
  -e SHOKO_URL=http://192.168.1.100 \
  -e SHOKO_PORT=8111 \
  -e HW_ACCEL=auto \
  -v /mnt/user/appdata/dango:/config \
  -v /tmp/dango-transcode:/transcode \
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
      - SHOKO_URL=http://192.168.1.100
      - SHOKO_PORT=8111
      - SHOKO_API_KEY=
      - HW_ACCEL=auto
    devices:
      - /dev/dri:/dev/dri
    volumes:
      - ./appdata:/config
      - /tmp/dango-transcode:/transcode
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
| `TRANSCODE_DIR` | `/transcode` | Scratch directory for remuxing and video transcoding buffers. |
| `SHOKO_URL` | `http://192.168.1.100` | IP or URL of your Shoko Server instance. |
| `SHOKO_PORT` | `8111` | Shoko Server port. |
| `SHOKO_API_KEY` | *(empty)* | Optional Shoko API key. |
| `HW_ACCEL` | `auto` | Hardware acceleration mode: `auto`, `vaapi`, `nvenc`, or `software`. |

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
