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
DEFAULT_CONFIG_TEMPLATE="/app/defaults/config.json"

log "Starting Arma Reforger Server setup..."

# Ensure directories exist
mkdir -p "$SERVER_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOGS_DIR"

# Ensure steam user can write to bind-mounted appdata paths.
chown -R steam:steam "$SERVER_DIR" "$CONFIG_DIR" "$LOGS_DIR" 2>/dev/null || true
chmod -R ug+rwX "$SERVER_DIR" "$CONFIG_DIR" "$LOGS_DIR" 2>/dev/null || true

# Normalize and seed config.json before download so users always get a file in appdata.
if [ -d "$CONFIG_DIR/config.json" ]; then
    log "WARNING: $CONFIG_DIR/config.json is a directory; renaming it and creating a valid file"
    mv "$CONFIG_DIR/config.json" "$CONFIG_DIR/config.json.dir.bak"
fi

if [ ! -f "$CONFIG_DIR/config.json" ]; then
    if [ -f "$DEFAULT_CONFIG_TEMPLATE" ]; then
        log "No config.json found; creating one from default template"
        cp "$DEFAULT_CONFIG_TEMPLATE" "$CONFIG_DIR/config.json"
    else
        log "ERROR: Default config template missing at $DEFAULT_CONFIG_TEMPLATE"
        exit 1
    fi
fi

# Auto-fix legacy fields from older flat-structure templates (for backward compatibility with persisted configs)
if command -v jq >/dev/null 2>&1; then
    # Remove any old flat-structure fields that shouldn't exist in new nested schema
    LEGACY_FIELDS='["serverName", "serverDescription", "gameType", "map", "mission", "modsList", "autoSaveInterval", "passwordProtected", "playerPassword", "voiceChat", "battleEye", "spawnPoints", "fastBoot", "maxFps", "difficulty", "gamePort", "queryPort", "a2sQueryPort"]'
    for field in $(echo "$LEGACY_FIELDS" | jq -r '.[]'); do
        if jq -e ".$field" "$CONFIG_DIR/config.json" >/dev/null 2>&1; then
            log "Removing legacy flat-structure field: $field"
            TMP_CONFIG="$CONFIG_DIR/config.json.tmp"
            jq "del(.$field)" "$CONFIG_DIR/config.json" > "$TMP_CONFIG"
            mv "$TMP_CONFIG" "$CONFIG_DIR/config.json"
        fi
    done
fi

cp "$CONFIG_DIR/config.json" "$SERVER_DIR/config.json" 2>/dev/null || true

# Download/update server files via SteamCMD.
log "Downloading server files via SteamCMD (App ID: $APP_ID)..."

install_with_steamcmd() {
    local mode="$1"
    local cmd

    case "$mode" in
        linux)
            cmd="$STEAM_DIR/steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir $SERVER_DIR +login anonymous +app_update $APP_ID validate +quit"
            ;;
        linux64)
            cmd="$STEAM_DIR/steamcmd.sh +@sSteamCmdForcePlatformType linux +@sSteamCmdForcePlatformBitness 64 +force_install_dir $SERVER_DIR +login anonymous +app_update $APP_ID validate +quit"
            ;;
        *)
            return 1
            ;;
    esac

    log "SteamCMD attempt: $mode"
    set +e
    su steam -c "$cmd" >> "$LOGS_DIR/steamcmd.log" 2>&1
    local rc=$?
    set -e
    return $rc
}

if ! install_with_steamcmd linux; then
    log "SteamCMD linux attempt failed; trying linux 64-bit"
    if ! install_with_steamcmd linux64; then
        log "ERROR: All SteamCMD install attempts failed. See $LOGS_DIR/steamcmd.log"
        exit 1
    fi
    fi

# Verify installation
if [ ! -f "$SERVER_DIR/ArmaReforgerServer" ]; then
    log "ERROR: Server executable not found at $SERVER_DIR/ArmaReforgerServer"
    exit 1
fi

log "Server files installed successfully"

# Re-assert config after update in case SteamCMD touched install directory.
if [ ! -f "$CONFIG_DIR/config.json" ]; then
    log "ERROR: Config missing at $CONFIG_DIR/config.json after install"
    exit 1
fi

cp "$CONFIG_DIR/config.json" "$SERVER_DIR/config.json" 2>/dev/null || true

# Set proper permissions
chmod +x "$SERVER_DIR/ArmaReforgerServer"

# Start server with signal handling
log "Starting Arma Reforger Server..."
trap 'log "Shutting down..."; kill -TERM $SERVER_PID 2>/dev/null || true; exit 0' SIGTERM SIGINT

cd "$SERVER_DIR"
./ArmaReforgerServer -config "$CONFIG_DIR/config.json" 2>&1 &
SERVER_PID=$!

log "Server PID: $SERVER_PID"
wait $SERVER_PID 2>/dev/null || true

log "Server stopped"