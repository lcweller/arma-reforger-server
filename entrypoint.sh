#!/bin/bash
set -e

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Load environment or use defaults
STEAM_DIR="${STEAM_DIR:-/home/steam/steamcmd}"
SERVER_DIR="${SERVER_DIR:-/app/data/server}"
CONFIG_DIR="${CONFIG_DIR:-/app/data/config}"
LOGS_DIR="${LOGS_DIR:-/app/data/logs}"
APP_ID="1874900"

log "Starting Arma Reforger Server setup..."

# Ensure directories exist
mkdir -p $SERVER_DIR
mkdir -p $CONFIG_DIR
mkdir -p $LOGS_DIR

# Download/update server files via SteamCMD
log "Downloading server files via SteamCMD (App ID: $APP_ID)..."
log "Using platform: linux"

su steam -c "$STEAM_DIR/steamcmd.sh +@sSteamCmdForcePlatformType linux \
                        +@sSteamCmdForcePlatformBitness 64 \
                        +force_install_dir $SERVER_DIR \
                        +login anonymous \
                        +app_install $APP_ID validate \
                        +quit"

# Verify installation
if [ ! -f "$SERVER_DIR/ArmaReforgerServer" ]; then
    log "ERROR: Server executable not found at $SERVER_DIR/ArmaReforgerServer"
    exit 1
fi

log "Server files installed successfully"

# Setup config.json if provided via volume
if [ -f "$CONFIG_DIR/config.json" ]; then
    log "Using provided config.json"
    cp "$CONFIG_DIR/config.json" "$SERVER_DIR/config.json"
else
    log "WARNING: No config.json found, using default"
fi

# Set proper permissions
chmod +x "$SERVER_DIR/ArmaReforgerServer"

# Start server with signal handling
log "Starting Arma Reforger Server..."
trap 'log "Shutting down..."; kill -TERM $SERVER_PID 2>/dev/null || true; exit 0' SIGTERM SIGINT

cd "$SERVER_DIR"
./ArmaReforgerServer -config config.json 2>&1 &
SERVER_PID=$!

log "Server PID: $SERVER_PID"
wait $SERVER_PID 2>/dev/null || true

log "Server stopped"