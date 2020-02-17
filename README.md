# CSGO-Plugins
My Plugins:
*AntiStackDamage - CS:GO Fix Fix trigger_hurt that has Parent
*Auto_Retry - Remembers which maps the player played(SQLite DB). if the player plays for the first time on the map, then he automatically reconnects
  -Client Command:
    #sm_retryclear - Сleans the DB of maps played by the client
*EntWatch Hud - Entwatch 3 fo CS:GO with Hud + HudPos + Glow + Transfer of discarded items(Give) + Menus
*Hide_Teammates - Hides Teammates on the entire map or distance
  -Client Command:
    #sm_hide [<-1-CVAR_MAX_Distance>] (-1 - Disable, 0 - Enable on the entire map, 1-CVAR_MAX_Distance - Enable ont the Distance)
    #sm_hide - show menu
  -CVARS:
    #sm_hide_enabled <0/1> - Enable/Disable plugin
    #sm_hide_maximum <1000-8000> - The maximum distance a player can choose
*Map Music Dhook SoundLib2 - Disable Map Music with Volume Control + Menus
*block_use_pickup_weapon - Ignore PickUp Weapons with press E
*buttonwatcher - Buttons Watcher with Bans and Menus. Watching func_button, momentary_rot_button, func_rot_button. Reacts: Use and Damage
  -CVARS:
    #sm_buttons_view <0/1> - Enable/Disable Global the display Buttons
  -Admin Command:
    #sm_bban <target> [<time in minutes>] - Buttons Ban on time. (-1 temporarily, 0 permanently, 1-... - ban on time)
    #sm_unbban <target> - Buttons UnBan
    #sm_bbanlist - Currently BBanned Statistic
  -Client Command:
    #sm_bstatus - Show status client's Buttons Ban
    #sm_buttons - Enable/Disable showing the client the button clicks
*cash_damage - Top Defender + Cash for Damage + Show Damage
*helpmenu_multilang - Custom Multilang HelpMenu for new Clients. Show rules/Server Info/Clients Commands. Allows you to set your own text without Recompile plugin
  -Client Command:
    #sm_helpmenu - Show Helpmenu
    #F4 - Show Commands Menu(FakeClientCommand)
  -Admin Command:
    #sm_helpmenu_reload - Reload Config
  
