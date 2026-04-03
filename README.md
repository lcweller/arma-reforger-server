# Arma Reforger On Unraid: Exact Deployment Steps

This guide uses one deployment method only: Unraid Docker Add Container.

## Step 1: Prepare Unraid

1. Enable Docker in Unraid.
2. Ensure internet access from Unraid.
3. Ensure this path exists: `/mnt/user/appdata/arma-reforger`.

## Step 2: Configure Router

Forward these UDP ports to the Unraid server LAN IP:

1. `2001/udp`
2. `17777/udp`
3. `19999/udp`

## Step 3: Deploy With Unraid Add Container

1. Open Unraid Docker page.
2. Click Add Container.
3. Set `Name` to `arma-reforger`.
4. Set `Repository` to `ghcr.io/lcweller/arma-reforger-server:latest`.
5. Set `Network Type` to `bridge`.
6. Add path mapping: Host `/mnt/user/appdata/arma-reforger` -> Container `/app/data` (Read/Write).
7. Click Apply.

## Step 4: Wait For First Boot

1. Open container logs.
2. Wait for SteamCMD download/verify to finish.
3. Wait for container status to become `healthy`.

First boot may take several minutes.

## Step 5: Edit Server Config

Edit this file on Unraid:

`/mnt/user/appdata/arma-reforger/config/config.json`

This image supports full-line `//` comments in `config.json`.
To activate a preset, remove `//` from that block and restart the container.

Use this structure:

```json
{
  "bindAddress": "0.0.0.0",
  "bindPort": 2001,
  "publicAddress": "",
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

Change these values:

1. `publicAddress`
2. `rcon.password`
3. `game.passwordAdmin`
4. `game.name`

To switch scenarios:

1. Find the commented `"scenarioId"` preset lines in config.
2. Uncomment one preset line.
3. Restart container.

To enable mods:

1. Find the commented blocks inside `game.mods`.
2. Uncomment one or more full mod blocks.
3. Restart container.

## Step 6: Restart

1. Restart the container.
2. Check logs.
3. Confirm container remains `healthy`.

## Step 7: Test Connectivity

1. Test join from LAN.
2. Test join from external network.
3. If external join fails, re-check router forwards.

## Step 8: Optional Mods

Add mods under `game.mods` in config, then restart.

## Step 9: If Something Fails

1. Check `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`.
2. Check container logs for JSON schema errors.
3. If config keeps failing, re-open `/mnt/user/appdata/arma-reforger/config/config.json` and compare with [config/config.json](config/config.json).

## License

MIT License