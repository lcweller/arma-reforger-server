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

Edit `arma-reforger/config/config.json` after first startup (the container auto-creates this file if missing):

```json
{
  "publicAddress": "YOUR_PUBLIC_IP",
  "serverName": "My Server Name",
  "adminPassword": "YOUR_STRONG_ADMIN_PASSWORD",
  "maxPlayers": 32,
  "modsList": []
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
| `publicAddress` | Your server's public IP | Required |
| `serverName` | Display name in server browser | "My Arma Reforger Server" |
| `adminPassword` | Admin console password | Required |
| `maxPlayers` | Player limit | 32 |
| `gameType` | Game mode | "Conflict" |
| `map` | Default map | "Everon" |

### Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 2001 | UDP | Game traffic |
| 17777 | UDP | Server communication |
| 19999 | UDP | Server queries |

## Mods

1. Find mod ID from Steam Workshop URL
2. Add to `config.json` modsList array:

```json
"modsList": [
  {
    "modId": "5965550F24A0C152",
    "name": "Where Am I"
  }
]
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
# Check for SteamCMD errors or missing config
```

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