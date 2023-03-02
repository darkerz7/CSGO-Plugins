# CSGO Plugins
## AntiStackDamage
CS:GO Fix parented trigger_hurt

## AutoRestart - Automatically restarts the server at a specific time. Hud + Chat + Console Announce every minute(last minute - every second). AutoRetry clients when restarting the server
Cvar | Parameter | Description
--- | --- | ---
`sm_autorestart` | <0/1> | Enable/Disable Auto Restart
`sm_autorestart_time` | <0000-2359> | Time to restart server at
`sm_autorestart_wait` | <0-30> | Wait to restart server at in Minutes

Admin Command | Description
--- | ---
`sm_forcerestart [<time in minutes>]` | Force server restart in `<time>` minutes

## Auto Retry
### Remembers which maps players have played (SQLite DB). If player is playing a map for the first time, client will be forced to retry
Cvar | Parameter | Description
--- | --- | ---
`autoretry_maplist` | <0/1> | Enable/Disable using maplist
`autoretry_mode` | <0/1> | Mode for maplist. 0 - AutoRetry Only map in list. 1 - Everyone else
`autoretry_autodetect` | <0/1> | Autodetect map with particles. You need to disable the maplist

Client Command | Description
--- | ---
`sm_retryclear` | Сleans the DB of maps played by the client

Admin Command | Description
--- | ---
`sm_autoretry_reloadmaplist` | Reloads the list of maps

## EntWatch (Old)
### Entwatch 3 for CS:GO with Hud + HudPos + HudColor + Glow + Transfer of discarded items(Give) + Menus + Block Pick up items with E+Change HUD Channel

## ForceInputs
### Allows admins to force inputs on entities. (ent_fire)
Admin Command | Description
--- | ---
`sm_forceinput <classname/targetname/!self/!target/#hammerid> <input> [parameter]` | Perform an action on a specific entity
`sm_forceinputplayer <target> <input> [parameter]` | Perform an action on a specific player

## Map Music Dhook SoundLib2 Old
### Disable Map Music with Volume Control + Menus

## MapMusic_DZ Dhook SoundLib2
### Reworked MapMusic

## block_use_pickup_weapon
### Ignore PickUp Weapons with press E
