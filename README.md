# Arma Reforger Dedicated Server On Unraid

This guide is only for Unraid users deploying this image:

`ghcr.io/lcweller/arma-reforger-server:latest`

It includes every step from prerequisites to router setup, config edits, first boot validation, and common failure recovery.

## Important Port Mapping Clarification

You are correct: [Arma-Reforger.yaml](Arma-Reforger.yaml) already defines the container ports.

What this means in Unraid:

1. Do not invent different container ports.
2. Keep container ports fixed at `2001`, `17777`, and `19999` (UDP).
3. In Unraid UI you are choosing host-side exposure. In normal setups, host and container ports should match.

## 1. Unraid Prerequisites

Minimum:

- 4 CPU cores
- 6 GB RAM
- 20 GB free disk

Recommended:

- 8 CPU cores
- 12 GB RAM
- 50 GB SSD cache/appdata storage

Required:

1. Unraid Docker service enabled
2. Internet access from Unraid to Steam
3. A dedicated appdata folder path (example: `/mnt/user/appdata/arma-reforger`)

## 2. Router and Firewall Requirements

Forward these UDP ports from your router to your Unraid server LAN IP:

- `2001/udp` game traffic
- `17777/udp` query/A2S
- `19999/udp` RCON

Checklist:

1. Reserve/static DHCP your Unraid IP.
2. Create UDP forwards for all three ports.
3. If any upstream firewall exists, allow these UDP ports.
4. If ISP uses CGNAT, public listing/connectivity may fail until you get a public inbound path.

## 3. Create the Container in Unraid

In Unraid Docker page:

1. Click Add Container.
2. Name it something like `Test5`.
3. Set Image to `ghcr.io/lcweller/arma-reforger-server:latest`.
4. Set Restart Policy to `unless-stopped`.

Add one path mapping:

1. Host Path: `/mnt/user/appdata/arma-reforger`
2. Container Path: `/app/data`
3. Access Mode: Read/Write

Add port mappings (UDP):

1. Host `2001` -> Container `2001` UDP
2. Host `17777` -> Container `17777` UDP
3. Host `19999` -> Container `19999` UDP

Optional environment variable for debugging only:

1. Key: `ADDITIONAL_STARTUP_ARGS`
2. Value example: `-listScenarios`

## 4. First Start Behavior (Expected)

On first boot, the container will:

1. Create directories under `/app/data`.
2. Create `/app/data/config/config.json` if missing.
3. Download or verify Arma Reforger dedicated server files through SteamCMD.

This can take multiple minutes.

Expected files after first start:

- `/mnt/user/appdata/arma-reforger/config/config.json`
- `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`
- `/mnt/user/appdata/arma-reforger/server/...`

## 5. Edit config.json Correctly

Use this nested schema model (do not use old flat keys like `adminPassword` at root):

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

Required edits before public use:

1. `publicAddress`: set your public IP or DDNS hostname.
2. `rcon.password`: set a strong password.
3. `game.passwordAdmin`: set a strong password.
4. `game.name`: set your server name.

Optional edits:

1. `game.password` for private join password.
2. `game.maxPlayers`.
3. `game.scenarioId`.
4. `game.mods`.

Critical validation rules:

1. Keep nested `game` object structure.
2. `serverMinGrassDistance` must be `>= 50`.
3. Keep defaults for ports while validating startup.

## 6. Restart and Validate on Unraid

After config edits:

1. Restart the container in Unraid.
2. Watch logs.
3. Confirm container remains `Up` and transitions to `healthy`.

Validation checklist:

1. No JSON schema errors in logs.
2. No immediate shutdown after config load.
3. External clients can reach server (after router forwards).

## 7. Adding Mods

Add mods to `game.mods` in the persisted config:

```json
"mods": [
  {
    "modId": "5965550F24A0C152",
    "name": "Where Am I"
  }
]
```

Then restart the container.

## 8. Recovery and Troubleshooting (Unraid)

### A) Config errors keep returning after image update

Cause: persisted config in appdata overrides image defaults.

Fix:

1. Edit `/mnt/user/appdata/arma-reforger/config/config.json` directly.
2. Restart container.

### B) SteamCMD takes too long

Check:

- `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`

First run verify/download of ~11 GB can take time.

### C) Container starts then server not visible publicly

Check in order:

1. Router forwards are UDP and target Unraid IP.
2. Host and container ports are 2001/17777/19999.
3. `publicAddress` is correct.
4. ISP is not behind CGNAT.

### D) Need valid scenario list

Temporarily set env var in Unraid container:

- `ADDITIONAL_STARTUP_ARGS=-listScenarios`

Start once, read logs, choose scenario, remove the env var, restart.

## 9. Security Checklist

1. Change all placeholder passwords.
2. Use unique long random admin and RCON secrets.
3. Keep image updated.
4. Expose only required UDP ports.

## 10. Files in This Repository

- [config/config.json](config/config.json): known-good baseline template
- [entrypoint.sh](entrypoint.sh): startup and legacy config migration logic
- [Arma-Reforger.yaml](Arma-Reforger.yaml): reference compose configuration with the same port set used in this guide

## License

MIT License