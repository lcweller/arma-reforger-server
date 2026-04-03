#!/bin/bash
set -Eeuo pipefail

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
AUTO_UPDATE="${AUTO_UPDATE:-true}"
VALIDATE_ON_UPDATE="${VALIDATE_ON_UPDATE:-false}"
CHOWN_ON_START="${CHOWN_ON_START:-false}"
APP_ID="1874900"
DEFAULT_CONFIG_TEMPLATE="/app/defaults/config.json"
RUNTIME_CONFIG="$CONFIG_DIR/config.runtime.json"

on_error() {
    local exit_code="$1"
    local line_no="$2"
    log "ERROR: Startup failed at line $line_no (exit code: $exit_code)"
    exit "$exit_code"
}

trap 'on_error $? $LINENO' ERR

build_runtime_config() {
    # Support full-line JSONC comments in config.json so users can toggle presets.
    awk '!/^[[:space:]]*\/\//' "$CONFIG_DIR/config.json" > "$RUNTIME_CONFIG"
}

bool_is_true() {
    case "${1,,}" in
        1|true|yes|on) return 0 ;;
        *) return 1 ;;
    esac
}

run_as_steam() {
    if command -v gosu >/dev/null 2>&1; then
        gosu steam "$@"
    else
        su steam -s /bin/bash -c "$*"
    fi
}

run_steamcmd_update() {
    local validate_arg=""
    local cmd

    if bool_is_true "$VALIDATE_ON_UPDATE"; then
        validate_arg=" validate"
    fi

    cmd="$STEAM_DIR/steamcmd.sh +@sSteamCmdForcePlatformType linux +@sSteamCmdForcePlatformBitness 64 +force_install_dir $SERVER_DIR +login anonymous +app_update $APP_ID$validate_arg +quit"

    log "Running SteamCMD update (validate: $VALIDATE_ON_UPDATE)"
    set +e
    run_as_steam /bin/bash -lc "$cmd" >> "$LOGS_DIR/steamcmd.log" 2>&1
    local rc=$?
    set -e
    return "$rc"
}

log "Starting Arma Reforger Server setup..."

# Ensure directories exist
mkdir -p "$SERVER_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$LOGS_DIR"

# Ensure steam user can write to bind-mounted appdata paths.
# Recursive chown is expensive on large server dirs, so keep it optional.
if bool_is_true "$CHOWN_ON_START"; then
    chown -R steam:steam "$SERVER_DIR" "$CONFIG_DIR" "$LOGS_DIR" 2>/dev/null || true
fi
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

# Build runtime JSON (comments removed) before any jq processing.
build_runtime_config

if ! jq empty "$RUNTIME_CONFIG" >/dev/null 2>&1; then
    log "ERROR: Config is not valid after removing comment lines from $CONFIG_DIR/config.json"
    log "Hint: Keep comments on their own lines starting with //"
    exit 1
fi

# Migrate legacy flat configs in persisted appdata to the current nested schema.
if command -v jq >/dev/null 2>&1; then
    if jq -e 'has("game") | not or has("adminPassword") or has("serverName") or has("serverDescription") or has("maxPlayers") or has("passwordProtected") or has("gameType") or has("map") or has("modsList")' "$RUNTIME_CONFIG" >/dev/null 2>&1; then
        log "Detected legacy flat config structure; migrating to nested schema"
        LEGACY_BACKUP="$CONFIG_DIR/config.legacy.$(date +%Y%m%d-%H%M%S).json"
        cp "$CONFIG_DIR/config.json" "$LEGACY_BACKUP"

        TMP_CONFIG="$CONFIG_DIR/config.json.tmp"
        jq \
            --slurpfile legacy "$RUNTIME_CONFIG" \
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

        # Rebuild runtime config from migrated canonical JSON.
        build_runtime_config
    fi
fi

# Download/update server files via SteamCMD.
if [ -x "$SERVER_DIR/ArmaReforgerServer" ] && ! bool_is_true "$AUTO_UPDATE"; then
    log "AUTO_UPDATE is disabled and server executable exists; skipping SteamCMD update"
else
    log "Updating server files via SteamCMD (App ID: $APP_ID)..."
    if ! run_steamcmd_update; then
        log "ERROR: SteamCMD update failed. See $LOGS_DIR/steamcmd.log"
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

# Rebuild runtime config after update in case the user edited config.json comments.
build_runtime_config

if ! jq empty "$RUNTIME_CONFIG" >/dev/null 2>&1; then
    log "ERROR: Runtime config is invalid after install. Check $CONFIG_DIR/config.json comment formatting"
    exit 1
fi

# Set proper permissions
chmod +x "$SERVER_DIR/ArmaReforgerServer"

# Start server as PID 1 for clean signal handling.
log "Starting Arma Reforger Server..."
cd "$SERVER_DIR"
SERVER_CMD=(./ArmaReforgerServer -config "$RUNTIME_CONFIG")

if [ -n "$ADDITIONAL_STARTUP_ARGS" ]; then
    # shellcheck disable=SC2206
    EXTRA_ARGS=($ADDITIONAL_STARTUP_ARGS)
    SERVER_CMD+=("${EXTRA_ARGS[@]}")
fi

log "Launch command: ${SERVER_CMD[*]}"
exec "${SERVER_CMD[@]}"