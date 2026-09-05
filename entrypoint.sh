#!/bin/sh
set -e

# Default to Unraid nobody:users (PUID=99, PGID=100)
PUID=${PUID:-99}
PGID=${PGID:-100}
UMASK=${UMASK:-022}

umask "$UMASK"

echo "========================================================"
echo " Starting Dango Container"
echo " User UID: ${PUID}"
echo " User GID: ${PGID}"
echo " Umask:    ${UMASK}"
echo " Appdata:  /config (XDG_DATA_HOME: ${XDG_DATA_HOME})"
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

# Ensure data directory exists
mkdir -p /config/dango

# Set ownership of /config to user:group
chown -R "$PUID:$PGID" /config

# Execute process with dropped privileges via su-exec
# Using 'exec' ensures Node.js receives SIGTERM directly for clean SQLite WAL checkpoints
exec su-exec "$USER_NAME:$GROUP_NAME" "$@"
