# Arma Reforger Dedicated Server On Unraid

This document is an Unraid-only installation and operations guide for:

`ghcr.io/lcweller/arma-reforger-server:latest`

## 1. Before Starting

Minimum host resources:

- 4 CPU cores
- 6 GB RAM
- 20 GB free disk

Recommended host resources:

- 8 CPU cores
- 12 GB RAM
- 50 GB SSD-backed appdata/cache

Required conditions:

1. Unraid Docker service is enabled.
2. Unraid host can reach Steam servers.
3. A persistent appdata path is available, example: `/mnt/user/appdata/arma-reforger`.

## 2. Router and Firewall Requirements

Forward these UDP ports to the Unraid host LAN IP:

- `2001/udp` (game)
- `17777/udp` (query/A2S)
- `19999/udp` (RCON)

Checklist:

1. Reserve/static-map the Unraid IP in DHCP.
2. Create all three UDP forwards.
3. Allow these UDP ports in any upstream firewall.
4. If ISP uses CGNAT, public reachability may fail until a public inbound path is available.

## 3. Unraid Add Container Form (Exact Values)

Open Unraid Docker page, click Add Container, and fill these values.

Core fields:

1. `Name`: `arma-reforger` (or preferred name)
2. `Repository`: `ghcr.io/lcweller/arma-reforger-server:latest`
3. `Network Type`: `bridge`
4. `Restart Policy`: `unless-stopped`
5. `Privileged`: `off`

Important:

1. The image URL goes in the `Repository` field.
2. Do not place the image URL in Name, Template URL, or any path field.

Path mapping:

1. `Host Path 1`: `/mnt/user/appdata/arma-reforger`
2. `Container Path 1`: `/app/data`
3. Access mode: `Read/Write`

Port mappings (all UDP):

1. Host `2001` -> Container `2001`
2. Host `17777` -> Container `17777`
3. Host `19999` -> Container `19999`

Port rules:

1. Keep container ports fixed at `2001`, `17777`, `19999`.
2. Host ports should match container ports unless there is a specific conflict plan.
3. [Arma-Reforger.yaml](Arma-Reforger.yaml) already reflects this same port set.

Optional env var for scenario discovery:

1. Key: `ADDITIONAL_STARTUP_ARGS`
2. Value: `-listScenarios`
3. Remove after scenario selection.

## 4. First Boot Expectations

On first start, container will:

1. Create `/app/data/config`, `/app/data/logs`, `/app/data/server`.
2. Create `/app/data/config/config.json` if missing.
3. Download/verify server files through SteamCMD.

Expected host files:

- `/mnt/user/appdata/arma-reforger/config/config.json`
- `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`
- `/mnt/user/appdata/arma-reforger/server/...`

Note: first run can take several minutes while SteamCMD verifies/downloads files.

## 5. Edit config.json (Required)

Edit:

`/mnt/user/appdata/arma-reforger/config/config.json`

Use this schema shape:

```json
{
  "bindAddress": "0.0.0.0",
  "bindPort": 2001,
  "publicAddress": "local",
  "publicPort": 2001,
  "a2s": {
    "address": "0.0.0.0",
    "port": 17777
  },
  "rcon": {
    "address": "0.0.0.0",
    "port": 19999,
    "password": "CHANGE_ME_STRONG_RCON_PASSWORD",
    "permission": "monitor",
    "blacklist": [],
    "whitelist": []
  },
  "game": {
    "name": "My Arma Reforger Server",
    "password": "",
    "passwordAdmin": "CHANGE_ME_STRONG_ADMIN_PASSWORD",
    "admins": [],
    "scenarioId": "{3F2E005F43DBD2F8}Missions/CAH_Briars_Coast.conf",
    "maxPlayers": 32,
    "visible": true,
    "gameProperties": {
      "serverMaxViewDistance": 1600,
      "serverMinGrassDistance": 50,
      "networkViewDistance": 1500,
      "disableThirdPerson": false,
      "fastValidation": true,
      "battlEye": true,
      "VONDisableUI": false,
      "VONDisableDirectSpeechUI": false,
      "VONCanTransmitCrossFaction": false
    },
    "mods": []
  }
}
```

Mandatory edits before public use:

1. `publicAddress`: set public IP or DDNS hostname.
2. `rcon.password`: set a strong unique password.
3. `game.passwordAdmin`: set a strong unique password.
4. `game.name`: set desired server name.

Optional edits:

1. `game.password` for private access.
2. `game.maxPlayers`.
3. `game.scenarioId`.
4. `game.mods`.

Do not use legacy flat keys:

- `adminPassword` (root-level)
- `serverName`
- `modsList`
- `gameType`
- `map`

Validation-sensitive rule:

1. `game.gameProperties.serverMinGrassDistance` must be `>= 50`.

## 6. Restart and Validate

After saving config:

1. Restart container in Unraid.
2. Open container logs.
3. Confirm container status stays `Up` and reaches `healthy`.

Validation pass criteria:

1. No JSON schema validation errors.
2. No immediate shutdown after config load.
3. Server appears reachable by clients.

## 7. Add Mods

Add workshop mods under `game.mods`:

```json
"mods": [
  {
    "modId": "5965550F24A0C152",
    "name": "Where Am I"
  }
]
```

Restart container after any mod change.

## 8. Troubleshooting

### Config errors continue after image update

Cause:

1. Persisted appdata config overrides image defaults.

Fix:

1. Edit `/mnt/user/appdata/arma-reforger/config/config.json` directly.
2. Restart container.

### SteamCMD appears stuck

Check:

1. `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`

Note:

1. First deploy may spend significant time verifying/downloading (~11 GB).

### Server not visible externally

Check in order:

1. UDP forwards exist for 2001/17777/19999.
2. Forwards target correct Unraid LAN IP.
3. `publicAddress` is valid.
4. ISP/CGNAT is not blocking inbound reachability.

### Need scenario list

Set env var temporarily:

1. `ADDITIONAL_STARTUP_ARGS=-listScenarios`

Run once, read logs, choose scenario, remove env var, restart.

## 9. Installation Mistake-Proof Checklist

1. Repository field contains `ghcr.io/lcweller/arma-reforger-server:latest`.
2. Single volume mapping exists: `/mnt/user/appdata/arma-reforger` -> `/app/data`.
3. All three ports exist and are UDP.
4. Container ports are exactly 2001/17777/19999.
5. Router forwards exactly match those host UDP ports.
6. `config.json` uses nested `game` schema.
7. `serverMinGrassDistance` is at least 50.
8. Placeholder passwords replaced.
9. Container reaches `healthy` state.

## 10. Repository Reference Files

- [config/config.json](config/config.json): baseline config template
- [entrypoint.sh](entrypoint.sh): startup and legacy config migration behavior
- [Arma-Reforger.yaml](Arma-Reforger.yaml): reference port/volume layout

## License

MIT License