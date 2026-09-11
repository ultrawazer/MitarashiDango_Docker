#!/bin/sh
set -e

# Default to Unraid nobody:users (PUID=99, PGID=100)
PUID=${PUID:-99}
PGID=${PGID:-100}
UMASK=${UMASK:-022}

umask "$UMASK"

echo "========================================================"
echo " Starting MitarashiDango Container"
echo " User UID: ${PUID}"
echo " User GID: ${PGID}"
echo " Umask:    ${UMASK}"
echo " Appdata:  /config (XDG_DATA_HOME: ${XDG_DATA_HOME})"
echo " Transcode: ${TRANSCODE_DIR:-/transcode}"
echo "========================================================"

# Manage group
if ! getent group dango >/dev/null 2>&1; then
    if getent group "$PGID" >/dev/null 2>&1; then
        GROUP_NAME=$(getent group "$PGID" | cut -d: -f1)
    else
        addgroup -g "$PGID" dango
        GROUP_NAME="dango"
    fi
else
    GROUP_NAME="dango"
fi

# Manage user
if ! getent passwd dango >/dev/null 2>&1; then
    if getent passwd "$PUID" >/dev/null 2>&1; then
        USER_NAME=$(getent passwd "$PUID" | cut -d: -f1)
    else
        adduser -u "$PUID" -G "$GROUP_NAME" -h /app -s /bin/sh -D dango
        USER_NAME="dango"
    fi
else
    USER_NAME="dango"
fi

# Manage GPU hardware acceleration device nodes (/dev/dri)
if [ -d /dev/dri ]; then
    chmod 666 /dev/dri/* 2>/dev/null || true
    for node in /dev/dri/*; do
        if [ -e "$node" ]; then
            DEV_GID=$(stat -c '%g' "$node" 2>/dev/null || stat -f '%g' "$node" 2>/dev/null)
            if [ -n "$DEV_GID" ] && [ "$DEV_GID" != "0" ]; then
                DEV_GRP=$(getent group "$DEV_GID" | cut -d: -f1)
                if [ -z "$DEV_GRP" ]; then
                    DEV_GRP="gpu_${DEV_GID}"
                    addgroup -g "$DEV_GID" "$DEV_GRP" >/dev/null 2>&1 || true
                fi
                adduser "$USER_NAME" "$DEV_GRP" >/dev/null 2>&1 || true
            fi
        fi
    done
fi

# Ensure persistent data, extensions, and transcode directories exist
mkdir -p /config/dango/extensions
mkdir -p "${TRANSCODE_DIR:-/transcode}"

# Ensure /app/server/data/extensions links to persistent /config/dango/extensions
# This prevents permission errors and ensures dynamic extensions persist across restarts
mkdir -p /app/server/data
ln -sfn /config/dango/extensions /app/server/data/extensions
chown -R "$PUID:$PGID" /app/server/data

# Set ownership to user:group
chown -R "$PUID:$PGID" /config
chown -R "$PUID:$PGID" "${TRANSCODE_DIR:-/transcode}"

# Execute process with dropped privileges via su-exec
# Using 'exec' ensures Node.js receives SIGTERM directly for clean SQLite WAL checkpoints
exec su-exec "$USER_NAME:$GROUP_NAME" "$@"
