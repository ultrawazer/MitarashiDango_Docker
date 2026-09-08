# syntax=docker/dockerfile:1

# ------------------------------------------------------------------------------
# Stage 1: Builder
# ------------------------------------------------------------------------------
FROM node:22-alpine AS builder

WORKDIR /app

# Install git for cloning the repository
RUN apk add --no-cache git

# Build arguments for repository source and version/branch
ARG REPO_URL=https://github.com/ultrawazer/MitarashiDango.git
ARG BRANCH=main

# Clone repository
RUN git clone --depth 1 --branch ${BRANCH} ${REPO_URL} .

# Install dependencies (npm workspaces)
RUN npm ci

# Build both client (Vite) and server (TypeScript)
RUN npm run build

# Prune development dependencies
RUN npm prune --omit=dev --workspaces

# Safeguard in case workspace dependencies are fully hoisted to /app/node_modules
RUN mkdir -p /app/server/node_modules

# ------------------------------------------------------------------------------
# Stage 2: Production Runner
# ------------------------------------------------------------------------------
FROM node:22-alpine AS runner

# Install runtime utilities:
# - su-exec: lightweight privilege dropping (Alpine equivalent of gosu)
# - tzdata: timezone support (TZ env in Unraid)
# - ca-certificates: SSL certificates for API & scraper traffic
# - curl: health check probes
# - rclone: cloud sync support built into Dango
# - ffmpeg: media remuxing, subtitle extraction, audio transcoding
# - libva-intel-driver, intel-media-driver, mesa-va-gallium: GPU hardware acceleration
# - libva-utils: vainfo for hardware acceleration diagnostics
RUN apk add --no-cache \
    su-exec \
    tzdata \
    ca-certificates \
    curl \
    rclone \
    ffmpeg \
    libva-intel-driver \
    intel-media-driver \
    mesa-va-gallium \
    libva-utils

WORKDIR /app

# Copy production artifacts from builder
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/client/dist ./client/dist
COPY --from=builder /app/client/package.json ./client/
COPY --from=builder /app/server/dist ./server/dist
COPY --from=builder /app/server/package.json ./server/
COPY --from=builder /app/server/node_modules ./server/node_modules

# Copy startup script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Unraid & Container Environment Defaults
ENV NODE_ENV=production \
    PORT=3000 \
    PUID=99 \
    PGID=100 \
    UMASK=022 \
    XDG_DATA_HOME=/config \
    TRANSCODE_DIR=/transcode \
    EXTENSIONS_DIR=/config/dango/extensions

# Expose Web interface
EXPOSE 3000

# Persistent data mount points
VOLUME ["/config", "/transcode"]

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["node", "--max-old-space-size=512", "server/dist/server.js"]
