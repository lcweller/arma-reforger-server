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
ADDITIONAL_STARTUP_ARGS="${ADDITIONAL_STARTUP_ARGS:-}"
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

# Migrate legacy flat configs in persisted appdata to the current nested schema.
if command -v jq >/dev/null 2>&1; then
    if jq -e 'has("game") | not or has("adminPassword") or has("serverName") or has("serverDescription") or has("maxPlayers") or has("passwordProtected") or has("gameType") or has("map") or has("modsList")' "$CONFIG_DIR/config.json" >/dev/null 2>&1; then
        log "Detected legacy flat config structure; migrating to nested schema"
        LEGACY_BACKUP="$CONFIG_DIR/config.legacy.$(date +%Y%m%d-%H%M%S).json"
        cp "$CONFIG_DIR/config.json" "$LEGACY_BACKUP"

        TMP_CONFIG="$CONFIG_DIR/config.json.tmp"
        jq \
            --slurpfile legacy "$CONFIG_DIR/config.json" \
            '
                .publicAddress = ($legacy[0].publicAddress // .publicAddress) |
                .publicPort = ($legacy[0].publicPort // .publicPort) |
                .game.name = ($legacy[0].serverName // .game.name) |
                .game.password = (if ($legacy[0].passwordProtected // false) then ($legacy[0].playerPassword // .game.password) else .game.password end) |
                .game.passwordAdmin = ($legacy[0].adminPassword // .game.passwordAdmin) |
                .game.maxPlayers = ($legacy[0].maxPlayers // .game.maxPlayers) |
                .game.mods = ($legacy[0].modsList // .game.mods) |
                .game.gameProperties.disableThirdPerson = ($legacy[0].disableThirdPerson // .game.gameProperties.disableThirdPerson) |
                .game.gameProperties.battlEye = ($legacy[0].battleEye // .game.gameProperties.battlEye)
            ' "$DEFAULT_CONFIG_TEMPLATE" > "$TMP_CONFIG"
        mv "$TMP_CONFIG" "$CONFIG_DIR/config.json"
        log "Legacy config migrated and backup saved to $LEGACY_BACKUP"
    fi
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
SERVER_CMD=(./ArmaReforgerServer -config "$CONFIG_DIR/config.json")

if [ -n "$ADDITIONAL_STARTUP_ARGS" ]; then
    # shellcheck disable=SC2206
    EXTRA_ARGS=($ADDITIONAL_STARTUP_ARGS)
    SERVER_CMD+=("${EXTRA_ARGS[@]}")
fi

log "Launch command: ${SERVER_CMD[*]}"
"${SERVER_CMD[@]}" 2>&1 &
SERVER_PID=$!

log "Server PID: $SERVER_PID"
wait $SERVER_PID 2>/dev/null || true

log "Server stopped"