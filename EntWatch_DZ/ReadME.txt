Installation:
1. Open with Notepad addons/sourcemod/scripting/entwatch_csgo_dz.sp and comment out or uncomment the corresponding modules
2. Compile plugin.
3. Unzip everything into the appropriate folders.
	*Note that the colors are located in a different folder
4. Open with Notepad cfg/sourcemod/entwatch/scheme/classic.cfg and set your color values, defaults and server name
5. Add a new section to addons/sourcemod/configs/databases.cfg
	*Example:
		"EntWatch"
			{
				"driver"			"sqlite"
				"host"				"localhost"
				"database"			"entwatch-sqlite"
				"user"				"root"
				"pass"				""
				//"timeout"			"0"
				//"port"			"0"
			}
	*If you want to use mysql, manually create a new database
6. Restart Server

Features:
-New Syntax
-Removed some options from the config
-The plugin uses a ArrayList and not an array
-Has a module structure
-Correct operation with multiple buttons
-Possibly show cooldowns from game_ui(Right Click)
-It is possible to transfer a discarded or not yet selected item
-You can specify the reason for the eban
-Allows you to keep a eban history
-Allows you to change the cooldown and maximum amount of use right during the game
-Allows admins to spawn an item
-Has redesigned menus with detailed information
-Allows you to use the item in the crowd
-Allows highlighting items
-Information output in HUD, which can be configured by each player separately
-Block item pick up on E
-Allows you to set the channel for the output of the HUD
-Allows you to completely change the item

List of Modules:
*Chat		- Responsible for displaying chat special messages to players
*Debug		- Helps to view the list of plugin variables
*Eban		- Allows you to prevent players from pickuping items
*Extended logs	- Logging all actions. Example pickup or use item and etc.
*Forwards	- Forwards to communicate with other plugins
*Glow		- Responsible for highlighting special items on the map
*Hud		- Responsible for displaying a list of items in the HUD
*Menu		- Responsible for the Admin Menu of the Entwatch
*Natives	- Natives to communicate with other plugins
*Spawn Item	- Responsible for the possibility for admins to spawn an item
*Transfer	- Responsible for transfer items to admins
*Use Priority	- Responsible for the use of items regardless of the crowd or camera position.

Commands and CVARs for modules:
%Main
#Cvars:
	*entwatch_mode_teamonly		<0/1>	- Enable/Disable team only mode. Default 1
	*entwatch_delay_use		<0-60>	- Change delay before use. Default 3
	*entwatch_scheme		<name>	- The name of the scheme config. Default "classic"
#Admin CMDs:
	*sm_ew_reloadconfig					- Allows you to update the configuration
	*sm_setcooldown <hammerid> <cooldown>			- Allows you to change the item’s cooldown during the game
	*sm_setmaxuses <hammerid> <maxuses> [<even if over>]	- Allows you to change the maximum use of the item during the game, depending on whether the item was used to the end
	*sm_addmaxuses <hammerid> [<even if over>]		- Allows you to add 1 charge to the item, depending on whether the item was used to the end
	*sm_ewsetmode <hammerid> <newmode> <cooldown> <maxuses> [<even if over>]	- Allows you to completely change the item

%Module Debug
#Admin CMDs:
	*sm_ewdebugconfig	- Allows you to view a list of configuration items
	*sm_ewdebugarray	- Allows you to view a list of items
	*sm_ewdebugscheme	- Allows you to view the configuration of the scheme

%Module Eban
#Cvars:
	*entwatch_bantime		<0-43200>	- Default ban time. 0 - Permanent. Default 0
	*entwatch_banreason		<reason>	- Default ban reason. Default "Trolling"
	*entwatch_keep_expired_ban	<0/1>		- Enable/Disable keep expired bans. Default 1
	*entwatch_use_reason_menu	<0/1>	- Enable/Disable menu if the admin has not indicated a reason
#Admin CMDs:
	*sm_eban <target> [<duration>] [<reason>]	- Allows you to restrict the player to pick up items
	*sm_eunban <target> [<reason>]			- Allows you to unrestrict the player to pick up items
	*sm_ebanlist					- Displays a list of Ebanned players
#Client CMDs:
	*sm_status [<target(only admins)>]		- Allows you to check player status

%Module Glow
#Cvars:
	*entwatch_glow			<0/1>		- Enable/Disable the glow Global. Default 1
	*entwatch_glow_spawn		<0/1>		- Enable/Disable the glow after Spawn Items. Default 1
	*entwatch_glow_spawn_type	<0-3>		- Glow Type after Spawn Items. Default 0
	*entwatch_glow_drop_type	<0-3>		- Glow Type after Drop Items. Default 0

%Module Hud
#Cvars:
	*entwatch_display_enable	<0/1>		- Enable/Disable the display. Default 1
	*entwatch_display_cooldowns	<0/1>		- Show/Hide the cooldowns on the display. Default 1
	*entwatch_admins_see		<0/1>		- Enable/Disable admins see everything Items. Default 1
	*entwatch_hud_channel		<0-5>		- Change HUD Channel/Group Dynamic channel. Default 5
#Client CMDs:
	*sm_hud				- Switches the player’s display of the HUD
	*sm_hudname			- Switches the display of player names in HUD
	*sm_hudpos <x> <y>		- Allows you to set the position of the HUD
	*sm_hudcolor <R> <G> <B> <A>	- Allows you to set the color of the HUD

%Module Spawn Item
#Admin CMDs:
	*sm_espawnitem <receiver> <itemname> [<strip 0/1>] - Allows admin to spawn item

%Module Transfer
#Admin CMDs:
	*sm_etransfer <owner>/$<itemname> <receiver>	- Allows admin to transfer item