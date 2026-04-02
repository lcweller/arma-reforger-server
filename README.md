# Arma Reforger Dedicated Server Docker Image

A custom Docker image for running an Arma Reforger dedicated server, built from scratch with SteamCMD integration and published to GitHub Container Registry.

## Features

- **Custom Built**: Complete Dockerfile with Ubuntu 22.04 base and SteamCMD
- **Automated Publishing**: GitHub Actions CI/CD for multi-platform builds
- **Production Ready**: Health checks and signal handling
- **Easy Configuration**: External config mounting for simple modifications
- **Mod Support**: Volume mounting for Steam Workshop mods

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- GitHub account for publishing
- 6GB+ RAM, 4+ CPU cores, 20GB+ disk space

### 1. Clone and Setup

```bash
git clone https://github.com/YOUR_USERNAME/arma-reforger-server.git
cd arma-reforger-server

# Create one data directory (container creates subfolders automatically)
mkdir -p arma-reforger
```

### 2. Configure Server

Edit `arma-reforger/config/config.json` after first startup. Use the generated nested template and set at least your public address, admin password, and scenario:

```json
{
  "bindAddress": "0.0.0.0",
  "bindPort": 2001,
  "publicAddress": "YOUR_PUBLIC_IP_OR_DDNS",
  "publicPort": 2001,
  "a2s": {
    "address": "0.0.0.0",
    "port": 17777
  },
  "rcon": {
    "address": "0.0.0.0",
    "port": 19999,
    "password": "YOUR_STRONG_RCON_PASSWORD",
    "permission": "monitor",
    "blacklist": [],
    "whitelist": []
  },
  "game": {
    "name": "My Server Name",
    "password": "",
    "passwordAdmin": "YOUR_STRONG_ADMIN_PASSWORD",
    "admins": [],
    "scenarioId": "{3F2E005F43DBD2F8}Missions/CAH_Briars_Coast.conf",
    "maxPlayers": 32,
    "visible": true,
    "gameProperties": {
      "serverMaxViewDistance": 1600,
      "serverMinGrassDistance": 0,
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

### 3. Deploy

```bash
docker compose up -d
docker compose logs -f
```

## Configuration

### Server Settings

| Setting | Description | Default |
|---------|-------------|---------|
| `bindAddress` | Local bind interface | `0.0.0.0` |
| `bindPort` | Main game UDP port | `2001` |
| `publicAddress` | Public IP or DNS name advertised to clients | Required |
| `publicPort` | Public game UDP port | `2001` |
| `a2s.port` | Steam query UDP port | `17777` |
| `rcon.port` | RCON TCP/UDP port used by tooling | `19999` |
| `game.name` | Display name in server browser | `My Arma Reforger Server` |
| `game.passwordAdmin` | Admin console password | Required |
| `game.scenarioId` | Scenario configuration path | Required |
| `game.maxPlayers` | Player limit | `32` |

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 2001 | UDP | Game traffic |
| 17777 | UDP | Server communication |
| 19999 | UDP | Server queries |

## Mods

1. Find mod ID from Steam Workshop URL
2. Add to `config.json` under `game.mods`:

```json
"game": {
  "mods": [
    {
      "modId": "5965550F24A0C152",
      "name": "Where Am I"
    }
  ]
}
```

3. Restart container: `docker compose restart`

## Building Locally

```bash
# Build image
docker build -t arma-reforger-local .

# Run locally
docker run -p 2001:2001/udp -p 17777:17777/udp -p 19999:19999/udp \
  -v $(pwd)/arma-reforger:/app/data \
  arma-reforger-local
```

## Publishing to GitHub

1. Create GitHub repository: `YOUR_USERNAME/arma-reforger-server`
2. Push code to `main` branch
3. GitHub Actions will automatically build and publish to GHCR
4. Image available at: `ghcr.io/YOUR_USERNAME/arma-reforger-server:latest`

## Troubleshooting

### Server Not Starting
```bash
docker compose logs arma-reforger
# Check for SteamCMD errors, schema validation errors, or invalid scenarioId
```

### Config Validation Failures
- Make sure you are using the nested `game` structure, not the older flat schema
- Ensure `game.scenarioId` points to a real scenario config
- Keep ports on the defaults first: `2001`, `17777`, `19999`
- If in doubt, start from `config/config.json` in this repo and only change passwords, publicAddress, and server name first

### List Available Scenarios
Use an extra startup argument so you can inspect valid scenario paths without rebuilding the image:

```bash
docker run --rm \
  -e ADDITIONAL_STARTUP_ARGS="-listScenarios" \
  -v $(pwd)/arma-reforger:/app/data \
  ghcr.io/YOUR_USERNAME/arma-reforger-server:latest
```

On Unraid, add an environment variable named `ADDITIONAL_STARTUP_ARGS` and set it to `-listScenarios` for one run, then check the container logs.

### Port Conflicts
```bash
netstat -tlnup | grep -E "(2001|17777|19999)"
# Ensure ports are not in use by other services
```

### Mod Download Issues
- Verify mod IDs are correct
- Check Steam Workshop permissions
- Ensure sufficient disk space

## Security Notes

- Change default admin password
- Use strong passwords (20+ characters recommended)
- Keep image updated with latest security patches
- Limit host path access to appdata only

## Resource Requirements

- **Minimum**: 4 CPU cores, 6GB RAM, 20GB storage
- **Recommended**: 8 CPU cores, 12GB RAM, 50GB SSD storage
- **Network**: 1 Mbps+ upload speed

## License

MIT License - feel free to use and modify.