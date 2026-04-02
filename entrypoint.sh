#!/bin/bash
set -e

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Load environment or use defaults
STEAM_DIR="${STEAM_DIR:-/home/steam/steamcmd}"
SERVER_DIR="${SERVER_DIR:-/app/server}"
CONFIG_DIR="${CONFIG_DIR:-/app/config}"
APP_ID="${APP_ID:-1874900}"
BRANCH="${BRANCH:---}"

log "Starting Arma Reforger Server setup..."

# Download/update server files via SteamCMD
log "Downloading server files via SteamCMD (App ID: $APP_ID)..."
$STEAM_DIR/steamcmd.sh +force_install_dir $SERVER_DIR \
                        +login anonymous \
                        +app_update $APP_ID $BRANCH validate \
                        +quit

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