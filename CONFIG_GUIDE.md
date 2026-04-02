# Arma Reforger Server Configuration Guide

## Overview
The `config.json` file controls all server behavior. This file resides at `/mnt/user/appdata/arma-reforger/config/config.json` when deployed on Unraid.

## Valid Configuration Fields

### Network & Connectivity
- **bindAddress** (string): Local IP address to bind to. Default: `"0.0.0.0"` (all interfaces)
- **bindPort** (number): UDP port for game traffic. Default: `2001`. Must match container port mapping.
- **publicAddress** (string): Public IP for server browser. Use `"local"` for auto-detection or specify IPv4 address.
- **publicPort** (number): Public port visible to players. Default: `2001`.

### Server Identity
- **serverName** (string): Server name displayed in browser. Max 64 characters recommended.
- **serverDescription** (string): Server description shown in browser.
- **adminPassword** (string): Password for admin console access. Should be strong (20+ chars).

### Gameplay Settings
- **gameType** (string): Game mode. Valid values: `"Conflict"`, `"Deathmatch"`, `"Cooperative"`, etc.
- **map** (string): Default map. Examples: `"Everon"`, `"Provinggrounds"`, etc.
- **maxPlayers** (number): Player limit. Default: `32`. Adjust based on server capacity.
- **difficulty** (number): Mission difficulty. Range: `0` (easiest) to `2` (hardest).
- **spawnPoints** (number): Number of spawn point groups. Default: `3`.

### Mission & Content
- **mission** (string): Default mission file. Leave empty `""` for default.
- **modsList** (array): Array of mod objects to load. Example:
  ```json
  "modsList": [
    {
      "modId": "5965550F24A0C152",
      "name": "Where Am I"
    }
  ]
  ```

### Server Features
- **voiceChat** (boolean): Enable voice chat. Default: `true`
- **battleEye** (boolean): Enable BattlEye anti-cheat. Default: `true`
- **passwordProtected** (boolean): Require password to join. Default: `false`
- **playerPassword** (string): Password if passwordProtected is `true`. Leave empty if not used.

### Performance & Tweaks
- **autoSaveInterval** (number): Auto-save interval in seconds. Default: `300` (5 minutes)
- **fastBoot** (boolean): Enable fast boot mode. Default: `false`
- **maxFps** (number): Maximum server FPS. Default: `60`. Higher = more CPU usage.
- **disableThirdPerson** (boolean): Disable third-person camera. Default: `false`
- **disableFirstPersonGunCamera** (boolean): Disable first-person gun camera. Default: `false`

## Invalid Fields (Do NOT use)
The following fields are **NOT** allowed in the schema and will cause startup failure:
- `gamePort` - Invalid, use `bindPort` instead
- `queryPort` - Keep server query on main port
- `a2sQueryPort` - Not applicable in this version

## Example Configuration

```json
{
  "bindAddress": "0.0.0.0",
  "bindPort": 2001,
  "publicAddress": "local",
  "publicPort": 2001,
  "serverName": "My Awesome Server",
  "serverDescription": "A vanilla Arma Reforger server",
  "adminPassword": "SuperSecurePassword123!",
  "gameType": "Conflict",
  "map": "Everon",
  "maxPlayers": 32,
  "mission": "",
  "modsList": [],
  "autoSaveInterval": 300,
  "passwordProtected": false,
  "playerPassword": "",
  "voiceChat": true,
  "battleEye": true,
  "spawnPoints": 3,
  "fastBoot": false,
  "maxFps": 60,
  "difficulty": 2,
  "disableThirdPerson": false,
  "disableFirstPersonGunCamera": false
}
```

## Customization Tips

### Adding Mods
Find the mod ID from the Steam Workshop URL or in-game workshop, then add to `modsList`:
```json
"modsList": [
  {
    "modId": "YOUR_MOD_ID_HERE",
    "name": "Mod Display Name"
  }
]
```

### Adjusting Difficulty
- `0` = Easy
- `1` = Normal
- `2` = Hard

### Using a Custom Mission
Set the mission filename:
```json
"mission": "MyCustomMission.pbo"
```

### Password-Protected Server
```json
"passwordProtected": true,
"playerPassword": "JoinPassword456!"
```

## Auto-Healing
The container startup script automatically fixes common issues:
- If `publicAddress` contains `"YOUR_PUBLIC_IP"` placeholder, it's changed to `"local"`
- Invalid fields like `gamePort`, `queryPort`, `a2sQueryPort` are automatically removed

## Verification
After editing `config.json`, the server will validate it on startup. If there are schema errors, check:
1. All field names match exactly (case-sensitive)
2. No invalid fields are present
3. Field values are the correct type (string, number, boolean, array)
4. JSON syntax is valid (no trailing commas, proper quotes, etc.)

Use a JSON validator online if unsure: https://jsonlint.com/
