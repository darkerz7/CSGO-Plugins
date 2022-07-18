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

## EntWatch_DZ 
### Reworked EntWatch 3 for CS:GO

## EntWatch (Old)
### Entwatch 3 for CS:GO with Hud + HudPos + HudColor + Glow + Transfer of discarded items(Give) + Menus + Block Pick up items with E+Change HUD Channel

## ForceInputs
### Allows admins to force inputs on entities. (ent_fire)
Admin Command | Description
--- | ---
`sm_forceinput <classname/targetname/!self/!target/#hammerid> <input> [parameter]` | Perform an action on a specific entity
`sm_forceinputplayer <target> <input> [parameter]` | Perform an action on a specific player

## Hide_Teammates - Hides Teammates on the entire map or distance
Cvar | Parameter | Description
--- | --- | ---
`sm_hide_enabled` | <0/1> | Enable/Disable plugin
`sm_hide_maximum` | <1000-8000> | The maximum distance a player can choose

Client Command | Description
--- | ---
`sm_hide [<-1-CVAR_MAX_Distance>]` | (-1 - Disable, 0 - Enable on the entire map, 1-CVAR_MAX_Distance - Enable ont the Distance)
`sm_hide` | show menu
`sm_hideall` | toggle hide teammates on the entire map

## Map Music Dhook SoundLib2 Old
### Disable Map Music with Volume Control + Menus

## MapMusic_DZ Dhook SoundLib2
### Reworked MapMusic

## block_use_pickup_weapon
### Ignore PickUp Weapons with press E

## Button Watcher
### Buttons Watcher with Bans and Menus. Watching func_button, momentary_rot_button, func_rot_button. Reacts: Use and Damage
Cvar | Parameter | Description
--- | --- | ---
`sm_buttons_view` | <0/1> | Enable/Disable Global the display Buttons
`sm_buttons_timer` | <0.0/10.0> | Timer before showing the pressed button again

Admin Command | Description
--- | ---
`sm_bban <target> [<time in minutes>]` | Buttons Ban on time. (-1 temporarily, 0 permanently, 1-... - ban on time)
`sm_unbban <target>` | Buttons UnBan
`sm_bbanlist` | Currently BBanned Statistic

Client Command | Description
--- | ---
`sm_bstatus` | Show status client's Buttons Ban
`sm_buttons` | Enable/Disable showing the client the button clicks

## Helpmenu Multilang
### Custom Multilang HelpMenu for new Clients. Show rules/Server Info/Clients Commands. Allows you to set your own text without Recompile plugin
Client Command | Description
--- | ---
`sm_helpmenu` | Show Helpmenu
`F4` | Show Commands Menu(FakeClientCommand)

Admin Command | Description
--- | ---
`sm_helpmenu_reload` | Reload Config

## topdefenders_perk
### TopDefenders, TopInfectors, Perks, built-in Downloadlist, Show Damage (Current damage, Kills, Total damage), Show Infect (Nickname victim, Total infected), Store Integration. 
### Perk - Trail/Sprite/Model, Add Speed, Reduced Gravity, immunity to first infection and more

### Top Defenders Config
```
- Configure perk/HUD position/Hud colors in addons\sourcemod\configs\topdefenders.cfg
- Built-in Downloadlist in addons\sourcemod\configs\topdefenders_downloadlist.ini
- You can configure a few perks per place(only one of the type), see ConfigFile
- In order to integrate the shop you must uncomment #define SHOP and configure function names SHOP_SET_CREDITS_FUNC(Shop_SetClientCredits) and SHOP_GET_CREDITS_FUNC(Shop_GetClientCredits)
```
Cvar | Parameter | Description
--- | --- | ---
`sm_topdefenders_enable` | <0/1> | Enable/Disable plugin
`sm_topdefenders_topcount` | <3/15> | Number of top defenders to display
`sm_topdefenders_perk` | <0/1> | Enable top defender perks
`sm_topdefenders_cashdiv` | <0/50> | Money for damage - Damage divider (Cash=Cash+Damage/Divider) 0 - Disable
`sm_topdefenders_infectors_enable` | <0/1> | Enable Top Infector Addon
`sm_topdefenders_infectors_topcount` | <3/15> | Number of people to top Infector
`sm_topdefenders_infectors_perk` | <0/1> | Gives Infector perk for the top Infector
`sm_topdefenders_immunity_chance` | <0/100> | Сhance of immunity from infection if prescribed in the configuration file
`sm_topdefenders_immunity_minplayers` | <10/64> | Minimum players for immunity
`sm_topdefenders_showdamage` | <0/1> | Enable/Disable Show Hint Damage Addon

Admin Command | Description
--- | ---
`sm_topdefenders_config_test1` | Test Config Top Defenders
`sm_topdefenders_config_test2` | Test Config Top Infectors
`sm_topdefenders_refresh` | Refresh Config without show

Client Command | Description
--- | ---
`sm_pr` | Remove Perk from yourself

