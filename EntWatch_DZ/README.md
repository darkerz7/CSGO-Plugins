# Installation:
1. Open with Notepad addons/sourcemod/scripting/entwatch_csgo_dz.sp and comment out or uncomment the corresponding modules
2. Compile plugin.
3. Unzip everything into the appropriate folders. *(Note that the colors are located in a different folder)*
4. Open with Notepad cfg/sourcemod/entwatch/scheme/classic.cfg and set your color values, defaults and server name
5. Add a new section to addons/sourcemod/configs/databases.cfg `(If you want to use mysql, manually create a new database)*
```
"EntWatch"
    {
        "driver"            "sqlite"
        "host"              "localhost"
        "database"          "entwatch-sqlite"
        "user"              "root"
        "pass"              ""
        //"timeout"         "0"
        //"port"            "0"
    }
```
6. Restart Server

# Features:
- New Syntax
- Removed some options from the config
- The plugin uses a ArrayList and not an array
- Has a module structure
- Correct operation with multiple buttons
- Possibly show cooldowns from game_ui(Right Click)
- It is possible to transfer a discarded or not yet selected item
- You can specify the reason for the eban
- Allows you to keep a eban history
- Allows you to change the cooldown and maximum amount of use right during the game
- Allows admins to spawn an item
- Has redesigned menus with detailed information
- Allows you to use the item in the crowd
- Allows highlighting items
- Information output in HUD, which can be configured by each player separately
- Block item pick up on E
- Allows you to set the channel for the output of the HUD
- Allows you to completely change the item
- Allows you to eban a disconnected player
- Allows you to track 2 buttons
- Allows to lock item

# List of Modules:
Modules | Description
--- | ---
Chat | Responsible for displaying chat special messages to players
Debug | Helps to view the list of plugin variables
Eban | Allows you to prevent players from pickuping items
Extended logs | Logging all actions. Example pickup or use item and etc.
Forwards | Forwards to communicate with other plugins
Glow | Responsible for highlighting special items on the map
Hud | Responsible for displaying a list of items in the HUD
Menu | Responsible for the Admin Menu of the Entwatch
Natives | Natives to communicate with other plugins
Spawn Item | Responsible for the possibility for admins to spawn an item
Transfer | Responsible for transfer items to admins
Use Priority | Responsible for the use of items regardless of the crowd or camera position.
Offline Eban | Responsible for Eban a disconnected player

# Commands and CVARs for modules:
## Main
### Cvars:

Cvar | Paramters | Description
--- | --- | ---
`entwatch_mode_teamonly` | `<0/1>` | Enable/Disable team only mode. (Default 1)
`entwatch_delay_use` | `<0.0-60.0>` | Change delay before use. (Default 3.0)
`entwatch_scheme` | `<name>` | The name of the scheme config. (Default `"classic"`)
`entwatch_blockepick` | `<0/1>` | Enable/Disable blocking E-pickup. (Default 1)
`entwatch_use_priority` | `<0/1>` | Enable/Disable forced pressing of the button. (Default 1)
`entwatch_globalblock` | `<0/1>`	| Blocks the pickup of any items by players. (Default 0)

### Admin Commands:
Command | Description
--- | ---
`sm_ew_reloadconfig` | Allows you to update the configuration
`sm_setcooldown <hammerid> <cooldown>` | Allows you to change the item’s cooldown during the game
`sm_setmaxuses <hammerid> <maxuses> [<even if over>]` | Allows you to change the maximum use of the item during the game, depending on whether the item was used to the end
`sm_addmaxuses <hammerid> [<even if over>]` |  Allows you to add 1 charge to the item, depending on whether the item was used to the end
`sm_ewsetmode <hammerid> <newmode> <cooldown> <maxuses> [<even if over>]` | Allows you to completely change the item
`sm_ewsetname <hammerid> <newname>` | Allows you to change the item’s name(Chat)
`sm_ewsetshortname <hammerid> <newshortname>` | Allows you to change the item’s shortname(HUD)
`sm_setcooldown2 <hammerid> <cooldown>` | Allows you to change the item’s cooldown on second button during the game
`sm_setmaxuses2 <hammerid> <maxuses> [<even if over>]` | Allows you to change the maximum use of the item on second button during the game, depending on whether the item was used to the end
`sm_addmaxuses2 <hammerid> [<even if over>]` | Allows you to add 1 charge to the item on second button, depending on whether the item was used to the end
`sm_ewsetmode2 <hammerid> <newmode> <cooldown> <maxuses> [<even if over>]` | Allows you to completely change the item on second button
`sm_ewblock <hammerid> <0/1>` | Allows you to block an item during the game. Similar to the "blockpickup" property
`sm_ewlockbutton <hammerid> <0/1>` | Allows to lock item (first button)
`sm_ewlockbutton2 <hammerid> <0/1>` | Allows to lock second button of item

## Module Debug
### Admin Commands:
Command | Description
--- | ---
`sm_ewdebugconfig` | Allows you to view a list of configuration items
`sm_ewdebugarray` | Allows you to view a list of items
`sm_ewdebugscheme` | Allows you to view the configuration of the scheme

## Module Eban
### Cvars:
Cvar | Parameters | Description
--- | --- | ---
`entwatch_bantime` | <0-43200> | Default ban time. 0 - Permanent. (Default 0)
`entwatch_banreason` | `<reason>` | Default ban reason. (Default `"Trolling"`)
`entwatch_keep_expired_ban` | <0/1> | Enable/Disable keep expired bans. (Default 1)
`entwatch_use_reason_menu` | <0/1> | Enable/Disable menu if the admin has not indicated a reason

### Admin Commands:
Command | Description
--- | ---
`sm_eban <target> [<duration>] [<reason>]` | Allows you to restrict the player to pick up items
`sm_eunban <target> [<reason>]` | Allows you to unrestrict the player to pick up items
`sm_ebanlist` | Displays a list of Ebanned players

## Client Commands:
Command | Description
--- | ---
`sm_status [<target (admin only)>]` | Allows you to check player status
## Ovverride Admin Access:
Command | Description
--- | ---
`sm_eban_perm` | Allows admins to issue and remove a permanent EBan
`sm_eban_long` | Allows admins to issue a EBan for more than 12 hours

## Module Glow (Deprecated)
### Cvars:
Cvar | Parameters | Description
--- | --- | ---
`entwatch_glow` | <0/1> | Enable/Disable the glow Global. (Default 1)
`entwatch_glow_spawn` | <0/1> | Enable/Disable the glow after Spawn Items. (Default 1)
`entwatch_glow_spawn_type` | <1 to 3> | Glow Type after Spawn Items, set -1 to stop glow. (Default 0)
`entwatch_glow_drop_type` | <1 to 3> | Glow Type after Drop Items, set -1 to stop glow. (Default 0)

## Module HighLight
### Cvars:
Cvar | Parameters | Description
--- | --- | ---
`entwatch_hl_wtype` | <0 to 6> | Type of HighLighting of items. 0 - Disable, 1 - All, 2 - Team, 3 - Privilege All, 4 - Privilege Team, 5 - Admin and Privilege All, 6 - Admin and Privilege Team. (Default 1)
`entwatch_hl_wcolor` | <0/1> | Color of HighLighting of items. 0 - Color from Item, 1 - Rainbow. (Default 0)
`entwatch_hl_ptype` | <0 to 6> | Type of HighLighting of players that own the item. 0 - Disable, 1 - All, 2 - Team, 3 - Privilege All, 4 - Privilege Team, 5 - Admin and Privilege All, 6 - Admin and Privilege Team. (Default 0)
`entwatch_hl_pcolor` | <0/1> | Color of HighLighting of players that own the item. 0 - Color from Item, 1 - Rainbow. (Default 0)
`sv_highlight_distance` | `<integer>` | Distance of HighLighting. (Default 500)
`sv_highlight_duration` | `<float>` | Duration of HighLighting. (Default 3.5)

## Module Chat
### Cvars:
Cvar | Parameters | Description
--- | --- | ---
`entwatch_adminchat_mode` | <0-2> | Change AdminChat Mode (0 - All Messages, 1 - Only Pickup/Drop Items, 2 - Nothing). (Default 0)

## Module Hud
### Cvars:
Cvar | Parameters | Description
--- | --- | ---
`entwatch_display_enable` | <0/1> | Enable/Disable the display. (Default 1)
`entwatch_display_cooldowns` | <0/1> | Show/Hide the cooldowns on the display. (Default 1)
`entwatch_admins_see` | <0/1> | Enable/Disable admins see everything Items. (Default 1)
`entwatch_hud_channel` | <0-5> | Change HUD Channel/Group Dynamic channel. (Default 5)
`entwatch_zm_noitem_pry` | <0/1> | Enable/Disable zm pry human Items if zms without items. (Default 0)

### Client Commands:
Command | Description
--- | ---
`sm_hud` | Switches the player’s display of the HUD
`sm_hudname` | Switches the display of player names in HUD
`sm_hudpos <x> <y>` | Allows you to set the position of the HUD
`sm_hudcolor <R> <G> <B> <A>` |  Allows you to set the color of the HUD

## Module Spawn Item
### Admin Commands:
Command | Description
--- | ---
`sm_espawnitem <receiver> <itemname> [<strip 0/1>]` | Allows admin to spawn item

## Module Transfer
### Admin Commands:
Command | Description
--- | ---
`sm_etransfer <owner>/$<itemname> <receiver>` | Allows admin to transfer item

## Module Offline Eban
### Cvars:
Cvar | Parameter | Description
--- | --- | ---
`entwatch_offline_clear_time` | <1/240> | Time during which data is stored. (Default 30)
### Admin Commands:
Command | Description
--- | ---
`sm_eoban` | Allows admin eban disconnected player

# Migration
## 3.DZ.20 to 3.DZ.21

You need to run the following queries:

### MYSQL
```sql
ALTER TABLE `EntWatch_Old_Eban` MODIFY COLUMN `id` int(10) unsigned NOT NULL auto_increment;
```

### SQLITE
```sql
ALTER TABLE `EntWatch_Old_Eban` RENAME TO `EntWatch_tmp`;
CREATE TABLE IF NOT EXISTS `EntWatch_Old_Eban`(	`id` INTEGER PRIMARY KEY AUTOINCREMENT, `client_name` varchar(32) NOT NULL, `client_steamid` varchar(64) NOT NULL, `admin_name` varchar(32) NOT NULL, `admin_steamid` varchar(64) NOT NULL, `server` varchar(64), `duration` INTEGER NOT NULL, `timestamp_issued` INTEGER NOT NULL, `reason` varchar(64), `reason_unban` varchar(64), `admin_name_unban` varchar(32), `admin_steamid_unban` varchar(64), `timestamp_unban` INTEGER);
INSERT INTO `EntWatch_Old_Eban` SELECT * FROM `EntWatch_tmp`;
DROP TABLE `EntWatch_tmp`;
```

# Recommended commands to add to bspconvar whitelist
```
sm_setcooldown 1
sm_setmaxuses 1
sm_addmaxuses 1
sm_ewsetmode 1
sm_ewsetname 1
sm_ewsetshortname 1
sm_setcooldown2 1
sm_setmaxuses2 1
sm_addmaxuses2 1
sm_ewsetmode2 1
sm_ewblock 1
sm_ewlockbutton 1
sm_ewlockbutton2 1
```
