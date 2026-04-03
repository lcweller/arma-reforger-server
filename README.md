# Arma Reforger Server On Unraid: Step-By-Step

This is a direct installation checklist. Follow each step in order.

## Step 1: Prepare Unraid

1. Ensure Docker is enabled in Unraid.
2. Create appdata folder: `/mnt/user/appdata/arma-reforger`.
3. Confirm Unraid has internet access.

## Step 2: Configure Router

Forward these UDP ports to your Unraid server LAN IP:

1. `2001/udp`
2. `17777/udp`
3. `19999/udp`

## Step 3: Add Container In Unraid

In Unraid Docker page, click Add Container and set:

1. `Name`: `arma-reforger`
2. `Repository`: `ghcr.io/lcweller/arma-reforger-server:latest`
3. `Network Type`: `bridge`
4. `Restart Policy`: `unless-stopped`
5. `Privileged`: `off`

Add path:

1. `Host Path`: `/mnt/user/appdata/arma-reforger`
2. `Container Path`: `/app/data`
3. `Access Mode`: `Read/Write`

Set ports (UDP):

1. Host `2001` -> Container `2001`
2. Host `17777` -> Container `17777`
3. Host `19999` -> Container `19999`

Click Apply to create/start the container.

## Step 4: Wait For First Boot

1. Open container logs.
2. Wait for SteamCMD download/verify to finish.
3. Wait until container status is `healthy`.

First start can take several minutes.

## Step 5: Edit Server Config

Edit this file on Unraid:

`/mnt/user/appdata/arma-reforger/config/config.json`

Use this structure:

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

Change these values before public use:

1. `publicAddress` to public IP or DDNS
2. `rcon.password`
3. `game.passwordAdmin`
4. `game.name`

## Step 6: Restart Container

1. Restart container in Unraid.
2. Open logs.
3. Confirm no JSON schema errors.
4. Confirm container stays `healthy`.

## Step 7: Join Test

1. Join from LAN first.
2. Then join from external network.
3. If external join fails, recheck router forwards.

## Step 8: Optional Mods

Add mods under `game.mods` in config:

```json
"mods": [
  {
    "modId": "5965550F24A0C152",
    "name": "Where Am I"
  }
]
```

Restart container after mod changes.

## Step 9: Common Fixes

If config errors persist after image updates:

1. Edit persisted file directly: `/mnt/user/appdata/arma-reforger/config/config.json`.
2. Restart container.

If first start looks stuck:

1. Check `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`.
2. Wait for SteamCMD to finish.

## Step 10: Final Checklist

1. Repository is `ghcr.io/lcweller/arma-reforger-server:latest`.
2. Volume is `/mnt/user/appdata/arma-reforger` -> `/app/data`.
3. UDP ports are 2001, 17777, 19999.
4. Router forwards match those UDP ports.
5. Container status is `healthy`.

## License

MIT License