# Kreedz mod

## Requirements
- AMX Mod X 1.9.0+
- ReGameDLL
- ReAPI
- [AmxxEasyHttp](https://github.com/Next21Team/AmxxEasyHttp/releases)

## Features
- Auto savepos on disconnect
- Settings system with auto save
- Practice in pause with checkpoints

## Commands
### Basic
| Command  | Description |
| --- | --- |
| `cp` | Make checkpoint |
| `tp` \| `gc` | Teleport to last checkpoint |
| `stuck` | Teleport to previous checkpoint |
| `p` \| `pause` \| `unpause` | Pause / unpause current run |
| `start` \| `restart` | Teleport to the start |
| `stop` \| `reset` | Stop timer |
| `nightvision` | Change nightvision mode |
| `+hook` | Enable / disable hook |
| `nc` \| `noclip` | Enable / disable noclip |
| `weapons` | Get all weapons |
| `spec` \| `ct` | Move to spectators / cts |

### Top
| Command  | Description |
| --- | --- |
| `top` \| `top15` | Top menu |
| `pro15` | Pro top |
| `nub15` \| `noob15` | Nub top |
| `cfr` | Show your personal best record |
| `rec` \| `record` | Show map best pro record |

### Menus
| Command  | Description |
| --- | --- |
| `invis` | Hide players and water menu |
| `menu` | Main menu |
| `settings` | Settings menu |
| `ljsmenu` | Jump stats menu |
| `mute` | Mute menu |

### Addons
| Command  | Description |
| --- | --- |
| `fog` | Enable / disable frames on ground feature |
| `sunglasses` | Fade screen for bright maps |
| `measure` | Measure distance from point A to B |
| `wr` | Show world record in hud |
| `goto` | Teleport to the player |
---

## Deployment
- Clone repository.
- Install dependencies `npm i`

#### Build project

```bash
npm run build
```

#### Watch project

```bash
npm run watch
```

#### Create bundle

```bash
npm run pack
```

### Special Thanks:
- [Credits](./CREDITS.md)
