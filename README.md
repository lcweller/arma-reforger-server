# Arma Reforger Dedicated Server Docker Image

Production-focused Docker image for hosting an Arma Reforger dedicated server with persisted config/data, SteamCMD auto-install/update, and Unraid-friendly deployment.

## What This Guide Covers

This README is a full start-to-finish deployment guide for:

1. Host prerequisites
2. Router and firewall requirements
3. Docker Compose deployment
4. Unraid deployment
5. Config file customization
6. Validation and troubleshooting

## Host Requirements

Minimum recommended host resources:

- 4 CPU cores
- 6 GB RAM
- 20 GB storage

Recommended for smoother performance:

- 8 CPU cores
- 12 GB RAM
- 50 GB SSD storage

Software prerequisites:

- Docker Engine
- Docker Compose (or Unraid Docker UI)
- Internet access to Steam content servers

## Network and Router Requirements

Arma Reforger needs inbound UDP traffic from the internet.

Open and forward these ports from your router to your Docker host LAN IP:

- UDP 2001 (game)
- UDP 17777 (A2S/query)
- UDP 19999 (RCON)

Checklist:

1. Reserve a static LAN IP for your Docker host (DHCP reservation is fine).
2. Create UDP port forwards for 2001, 17777, and 19999 to that host IP.
3. If host firewall is enabled, allow inbound UDP 2001/17777/19999.
4. If your ISP uses CGNAT, public hosting may fail unless you use a public IP solution.
5. Optional: use DDNS and set `publicAddress` to your DDNS hostname.

## Repository Layout

- [Dockerfile](Dockerfile)
- [entrypoint.sh](entrypoint.sh)
- [config/config.json](config/config.json)
- [Arma-Reforger.yaml](Arma-Reforger.yaml)

## Quick Deploy With Docker Compose

### 1. Clone

```bash
git clone https://github.com/YOUR_USERNAME/arma-reforger-server.git
cd arma-reforger-server
```

### 2. Create persistent appdata folder

```bash
mkdir -p arma-reforger
```

### 3. Start container

```bash
docker compose up -d
```

First startup can take several minutes. SteamCMD will download/verify server files (about 11 GB).

### 4. Watch logs

```bash
docker compose logs -f arma-reforger
```

Healthy path looks like:

- SteamCMD install/update completes
- server process starts
- container remains up and becomes healthy

## Unraid Deployment (Recommended for This Image)

### 1. Add container image

Use image:

`ghcr.io/lcweller/arma-reforger-server:latest`

### 2. Port mappings

Map host to container exactly:

- 2001/udp -> 2001/udp
- 17777/udp -> 17777/udp
- 19999/udp -> 19999/udp

### 3. Persistent path mapping

Map one host path to `/app/data`:

- Host path example: `/mnt/user/appdata/arma-reforger`
- Container path: `/app/data`

The container will use/create:

- `/app/data/config/config.json`
- `/app/data/logs/steamcmd.log`
- `/app/data/server/...`

### 4. Optional environment variable

You can pass extra startup args without rebuilding image:

- Name: `ADDITIONAL_STARTUP_ARGS`
- Example value: `-listScenarios`

### 5. Start and verify

Start the container and inspect logs in Unraid.

## config.json Reference

Use [config/config.json](config/config.json) as the base template.

### Known-good baseline

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

### What to change first

Before public use, change these values:

1. `publicAddress`
2. `rcon.password`
3. `game.passwordAdmin`
4. `game.name`

Optional changes:

1. `game.password` for private server access
2. `game.maxPlayers`
3. `game.scenarioId` to your desired mission
4. `game.mods` list

### Important schema notes

- Use the nested `game` structure.
- Do not use old flat fields such as `adminPassword`, `serverName`, `modsList`, `gameType`, or `map`.
- `game.gameProperties.serverMinGrassDistance` must be at least `50`.
- Keep default ports until server boots successfully.

## Adding Mods

Add workshop mods under `game.mods`:

```json
"mods": [
  {
    "modId": "5965550F24A0C152",
    "name": "Where Am I"
  }
]
```

Then restart container:

```bash
docker compose restart arma-reforger
```

## Scenario Discovery

If you need valid scenario IDs/paths, run one startup with `-listScenarios`.

Docker example:

```bash
docker run --rm \
  -e ADDITIONAL_STARTUP_ARGS="-listScenarios" \
  -v $(pwd)/arma-reforger:/app/data \
  ghcr.io/lcweller/arma-reforger-server:latest
```

In Unraid, set `ADDITIONAL_STARTUP_ARGS=-listScenarios` for one run and read container logs.

## Validate Your Deployment

After startup, validate in this order:

1. Container status is `Up` and eventually `healthy`.
2. No JSON schema errors in logs.
3. Server is visible/connectable from game clients.
4. Router-forwarded ports are reachable from outside your LAN.

Useful checks:

```bash
docker ps
docker logs --tail 200 <container_name>
```

## Troubleshooting

### Container exits with config schema errors

Use the exact structure from [config/config.json](config/config.json). Most failures are caused by old field names or out-of-range values.

### Server keeps reusing old broken config

If you bind mount appdata, existing config persists across image updates. Edit the mounted file directly:

- `/mnt/user/appdata/arma-reforger/config/config.json` on Unraid

### SteamCMD phase looks stuck

During first run, SteamCMD verify/download can take a while. Check:

- `/mnt/user/appdata/arma-reforger/logs/steamcmd.log`

### Server starts then disappears from browser

Verify:

1. Port forwards are UDP, not TCP.
2. Forwards target the correct host IP.
3. `publicAddress` is correct for internet clients.
4. ISP is not blocking/CGNAT-ing inbound traffic.

## Security Recommendations

1. Change all placeholder passwords.
2. Use long random admin and RCON passwords.
3. Keep host and image updated.
4. Only expose required ports.

## Build and Publish (Project Maintainers)

Build locally:

```bash
docker build -t arma-reforger-local .
```

Run locally:

```bash
docker run -p 2001:2001/udp -p 17777:17777/udp -p 19999:19999/udp \
  -v $(pwd)/arma-reforger:/app/data \
  arma-reforger-local
```

Push to GitHub and let Actions publish to GHCR:

1. Push to `main`
2. Wait for workflow completion
3. Pull `ghcr.io/lcweller/arma-reforger-server:latest`

## License

MIT License