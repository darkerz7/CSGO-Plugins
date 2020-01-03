//dif css and cs go:
//CVARs
//trail fix
//inc colors
//position hud
//translate
//show damage
//position and color HUDs
//top def HUDs on round start
//trail changed sprite
//cfg for sprite

#include <sourcemod>
#include <sdktools>
#include <csgocolors>

#define PLUGIN_VERSION "1.5.1go"
#define CS_TEAM_SPEC 1
//#define CS_TEAM_T 2
#define CS_TEAM_CT 3
//#define TRAIL_SPRITE_VMT "sprites/n4a/def_sprite_sao.vmt"
//#define TRAIL_SPRITE_VTF "sprites/n4a/def_sprite_sao.vtf"

//start round HUD message buffer
char str_hud_message[4096] = "";

//new Handle:Timer_Handle_Check;
new g_iAccount = -1;
new Handle:cvar_cash_damage_enable;
new Handle:cvar_top_enable;
new Handle:cvar_damage_div;
new Handle:cvar_damage_top;
new Handle:cvar_damage_rewarding_top;
new Handle:cvar_damage_cash_add;

new Handle:cvar_top_first_r;
new Handle:cvar_top_first_g;
new Handle:cvar_top_first_b;

new Handle:cvar_top_second_r;
new Handle:cvar_top_second_g;
new Handle:cvar_top_second_b;

new Handle:cvar_top_third_r;
new Handle:cvar_top_third_g;
new Handle:cvar_top_third_b;

new Handle:cvar_top_other_r;
new Handle:cvar_top_other_g;
new Handle:cvar_top_other_b;

new Handle:cvar_trail_first_r;
new Handle:cvar_trail_first_g;
new Handle:cvar_trail_first_b;

new Handle:cvar_trail_second_r;
new Handle:cvar_trail_second_g;
new Handle:cvar_trail_second_b;

new Handle:cvar_trail_third_r;
new Handle:cvar_trail_third_g;
new Handle:cvar_trail_third_b;

new Handle:cvar_trail_other_enable;
new Handle:cvar_trail_other_r;
new Handle:cvar_trail_other_g;
new Handle:cvar_trail_other_b;

new Handle:cvar_trail_rendermode;
new Handle:cvar_trail_alpha;

new Handle:cvar_speed;

new Handle:g_Arraysprite;

new Handle:g_hHudSynchronizer;

new player_damage[MAXPLAYERS + 1];

new trail[MAXPLAYERS+1] = -1;

new bool:block_timer[MAXPLAYERS + 1] = {false,...};
new player_current_damage[MAXPLAYERS + 1];

//cvar buffer
bool _enable_plugin=true;
int _damage_div=20;
bool _top_enable=true;
int _top_count=3;
bool _gift=true;
bool _cash_add=true;

int _top_first_r=255;
int _top_first_g=215;
int _top_first_b=0;

int _top_second_r=120;
int _top_second_g=120;
int _top_second_b=255;

int _top_third_r=42;
int _top_third_g=255;
int _top_third_b=42;

int _top_other_r=255;
int _top_other_g=0;
int _top_other_b=0;

int _trail_first_r=255;
int _trail_first_g=0;
int _trail_first_b=0;

int _trail_second_r=0;
int _trail_second_g=0;
int _trail_second_b=255;

int _trail_third_r=0;
int _trail_third_g=255;
int _trail_third_b=0;

bool _trail_other=true;
int _trail_other_r=255;
int _trail_other_g=255;
int _trail_other_b=0;

int _trail_rendermode=9;
int _trail_alpha=200;

float _speed_add=0.0;

public Plugin:myinfo = 
{
	name = "[ZR]Cash for damage & TopDefender & ShowDamage CS:GO",
	author = "DarkerZ [RUS]",
	description = "Players get money for damage",
	version = PLUGIN_VERSION,
	url = "net4all.ru"
}

public OnPluginStart()
{
	g_Arraysprite = CreateArray(PLATFORM_MAX_PATH);
	
	HookEvent("player_hurt", Hurt);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	//entity cash
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iAccount == -1)
	{
		SetFailState("[CS:GO] Give Cash - Failed to find offset for m_iAccount!");
	}
	//CVAR eneble plugin
	cvar_cash_damage_enable = CreateConVar("sm_cash_damage_enable", "1", "[Cash damage] Enabled/Disabled cash damage functionality, 0 = off/1 = on", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//CVAR diveder damage
	cvar_damage_div = CreateConVar("sm_cash_damage_div","20","[Cash damage] Divider (min 1/max 50)",FCVAR_NOTIFY,true, 1.0, true, 50.0);
	//CVAR enadle top
	cvar_top_enable = CreateConVar("sm_cash_damage_top_enable", "1", "[Cash damage] Enabled/Disabled cash damage top functionality, 0 = off/1 = on", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//CVAR show top count
	cvar_damage_top = CreateConVar("sm_cash_damage_top","3","[Cash damage] Count top on round end (min 3/max 15)",FCVAR_NOTIFY,true, 3.0, true, 15.0);
	//CVAR Gift
	cvar_damage_rewarding_top = CreateConVar("sm_cash_damage_gift_enable", "1", "[Cash damage] Enabled/Disabled cash damage top gift functionality, 0 = off/1 = on", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	//CVAR add to cash
	cvar_damage_cash_add = CreateConVar("sm_cash_damage_add_enable", "1", "[Cash damage] Enabled/Disabled cash damage add functionality, 0 = off/1 = on", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	//CVAR's colors
	//first
	cvar_top_first_r = CreateConVar("sm_cash_damage_first_red","255","[Cash damage] Color RED for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_first_g = CreateConVar("sm_cash_damage_first_green","215","[Cash damage] Color GREEN for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_first_b = CreateConVar("sm_cash_damage_first_blue","0","[Cash damage] Color BLUE for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//second
	cvar_top_second_r = CreateConVar("sm_cash_damage_second_red","120","[Cash damage] Color RED for Second on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_second_g = CreateConVar("sm_cash_damage_second_green","120","[Cash damage] Color GREEN for Second on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_second_b = CreateConVar("sm_cash_damage_second_blue","255","[Cash damage] Color BLUE for Second on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//third
	cvar_top_third_r = CreateConVar("sm_cash_damage_third_red","42","[Cash damage] Color RED for Third on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_third_g = CreateConVar("sm_cash_damage_third_green","255","[Cash damage] Color GREEN for Third on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_third_b = CreateConVar("sm_cash_damage_third_blue","42","[Cash damage] Color BLUE for Third on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//other
	cvar_top_other_r = CreateConVar("sm_cash_damage_other_red","255","[Cash damage] Color RED for Other on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_other_g = CreateConVar("sm_cash_damage_other_green","0","[Cash damage] Color GREEN for Other on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_top_other_b = CreateConVar("sm_cash_damage_other_blue","0","[Cash damage] Color BLUE for Other on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	
	//CVAR's colors sprites
	//first
	cvar_trail_first_r = CreateConVar("sm_cash_damage_sprite_first_red","255","[Cash damage] Color sprite RED for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_first_g = CreateConVar("sm_cash_damage_sprite_first_green","0","[Cash damage] Color sprite GREEN for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_first_b = CreateConVar("sm_cash_damage_sprite_first_blue","0","[Cash damage] Color sprite BLUE for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//second
	cvar_trail_second_r = CreateConVar("sm_cash_damage_sprite_second_red","0","[Cash damage] Color sprite RED for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_second_g = CreateConVar("sm_cash_damage_sprite_second_green","0","[Cash damage] Color sprite GREEN for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_second_b = CreateConVar("sm_cash_damage_sprite_second_blue","255","[Cash damage] Color sprite BLUE for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//third
	cvar_trail_third_r = CreateConVar("sm_cash_damage_sprite_third_red","0","[Cash damage] Color sprite RED for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_third_g = CreateConVar("sm_cash_damage_sprite_third_green","255","[Cash damage] Color sprite GREEN for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_third_b = CreateConVar("sm_cash_damage_sprite_third_blue","0","[Cash damage] Color sprite BLUE for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//other
	cvar_trail_other_enable = CreateConVar("sm_cash_damage_sprite_other_enable", "1", "[Cash damage] Enabled/Disabled cash damage sprite other functionality, 0 = off/1 = on", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_trail_other_r = CreateConVar("sm_cash_damage_sprite_other_red","255","[Cash damage] Color sprite RED for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_other_g = CreateConVar("sm_cash_damage_sprite_other_green","255","[Cash damage] Color sprite GREEN for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	cvar_trail_other_b = CreateConVar("sm_cash_damage_sprite_other_blue","0","[Cash damage] Color sprite BLUE for First on top (min 0/max 255)",FCVAR_NOTIFY,true, 0.0, true, 255.0);
	//configs sprite
	cvar_trail_rendermode = CreateConVar("sm_cash_damage_sprite_rendermode", "9", "[Cash damage] Rendermode for sprites (min 0/max 10)", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	cvar_trail_alpha = CreateConVar("sm_cash_damage_sprite_alpha", "200", "[Cash damage] Alpha for sprites (min 0/max 255)", FCVAR_NOTIFY, true, 0.0, true, 255.0);
	
	//CVAR speed
	cvar_speed = CreateConVar("sm_cash_damage_speed", "0.0", "[Cash damage] ADD speed for top (min 0.0/max 2.0)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	
	LoadTranslations("cash_damage.phrases");
	RegConsoleCmd("sm_dt", DeleteTrail, "[Cash damage] Delete Sprite and Color Skin");
	RegAdminCmd("sm_cash_damage_refresh", Refresh_cvar_admin, ADMFLAG_CONFIG, "[Cash damage] Refresh CVARs");
	
	//show damage HUD init
	g_hHudSynchronizer = CreateHudSynchronizer();
	
	Refresh_cvar();
	
	AutoExecConfig(true, "cash_damage");
	
	CreateTimer(5.0, Check_Human_Alive, _, TIMER_REPEAT);
}

public OnMapStart()
{
	//old materials downloads
	/*
	//add to download
	new String:file_vmt[255]; 
	Format(file_vmt, 255, "materials/%s", TRAIL_SPRITE_VMT); 
	new String:file_vtf[255]; 
	Format(file_vtf, 255, "materials/%s", TRAIL_SPRITE_VTF);
	AddFileToDownloadsTable(file_vmt); 
	AddFileToDownloadsTable(file_vtf);
	//precache
	PrecacheModel(file_vmt);
	*/
	
	//array sprites
	ClearArray(g_Arraysprite);
	//find cfg sprites
	new Handle:KvSprites = CreateKeyValues("n4a_sprite");
	new String:ConfigFile_Sprites[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile_Sprites, sizeof(ConfigFile_Sprites), "configs/tdef_sprite.cfg");
	if ( !FileToKeyValues(KvSprites, ConfigFile_Sprites) )
	{
		CloseHandle(KvSprites);
		LogError("[ERROR] Sprite can not convert file to keyvalues: %s", ConfigFile_Sprites);
		return;
	}

	// Find first sprite section
	KvRewind(KvSprites);
	new bool:sectionExists;
	sectionExists = KvGotoFirstSubKey(KvSprites);
	if ( !sectionExists )
	{
		CloseHandle(KvSprites);
		LogError("[ERROR] Sprite can not find first keyvalues subkey in file: %s", ConfigFile_Sprites);
		return;
	}

	new String:file_vmt[255];
	new String:file_vtf[255];
	
	new String:filename[PLATFORM_MAX_PATH];
	// Load all sprites
	while ( sectionExists )
	{
		KvGetString(KvSprites, "n4a_vmt", filename, sizeof(filename));
		Format(file_vmt, 255, "materials/%s", filename);
		AddFileToDownloadsTable(file_vmt);
		PushArrayString(g_Arraysprite, filename);
		//PushArrayCell(g_Arraysprite, PrecacheModel(file_vmt));
		
		KvGetString(KvSprites, "n4a_vtf", filename, sizeof(filename));
		Format(file_vtf, 255, "materials/%s", filename);
		AddFileToDownloadsTable(file_vtf);
		//PrecacheDecal(file_vtf);
		PrecacheModel(file_vmt);
		
		sectionExists = KvGotoNextKey(KvSprites);
	}

	CloseHandle(KvSprites);
}

public Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!_enable_plugin){
		return;
	}
	new client  = GetClientOfUserId(GetEventInt(event, "userid"));
	//who attacker
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker > 0 && attacker <= MaxClients){// fix 0 number client
		if(!IsFakeClient(attacker) && IsClientInGame(attacker) && attacker != GetClientOfUserId(GetEventInt(event, "userid")) && GetClientTeam(attacker) == CS_TEAM_CT)
		{
			//damage attacker
			new dmg = GetEventInt(event, "dmg_health");
			if(_cash_add){//add cash
				//current cash attacker
				new currentCash = GetEntData(attacker, g_iAccount);
				//current+dmg
				new addCash = currentCash + dmg / _damage_div;
				//PrintToChat(attacker,"DMG:%i,CUR:%i,ADD:%i",dmg,currentCash,addCash);
				//max cash 16000
				if (addCash > 16000){
					addCash=16000;
				}
				//set cash
				SetEntData(attacker, g_iAccount, addCash);
			}
			if(_top_enable){
				//damage for round
				player_damage[attacker] += dmg;
				//show full damage + current damage
				//PrintCenterText(attacker, "DMG:%i CUR:%i", player_damage[attacker], dmg);
			} else {
				//show current damage
				//PrintCenterText(attacker, "DMG:%i", dmg);
			}
			CalcDamage(client, attacker, dmg);
		}
	}
}

public Action:ShowDamage(Handle:timer, any:client)
{
	block_timer[client] = false;
	
	if (player_damage[client] <= 0 || !client)
	{
		return;
	}
	
	if (!IsClientInGame(client))
	{
		return;
	}
	/*if(_top_enable){
		//show full damage + current damage
		//PrintCenterText(client, "DMG:%i CUR:%i", player_damage[client], player_current_damage[client]);
		new String:sBuffer[128];
		FormatEx(sBuffer, 128, "DMG:%i CUR:%i", player_damage[client], player_current_damage[client]);
		SetHudTextParams(-1.0, 0.85, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSynchronizer, sBuffer);
	} else {
		//show current damage
		//PrintCenterText(client, "DMG:%i", player_current_damage[client]);
		new String:sBuffer[128];
		FormatEx(sBuffer, 128, "DMG:%i", player_current_damage[client]);
		SetHudTextParams(-1.0, 0.85, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(client, g_hHudSynchronizer, sBuffer);
	}*/
	new String:sBuffer[128];
	FormatEx(sBuffer, 128, "-%i", player_current_damage[client]);
	SetHudTextParams(0.3, 0.3, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
	ShowSyncHudText(client, g_hHudSynchronizer, sBuffer);
	player_current_damage[client] = 0;
}

CalcDamage(client, client_attacker, damage)
{	
	if (client_attacker == 0)
	{
		return;
	}
	
	if (IsFakeClient(client_attacker) || !IsClientInGame(client_attacker))
	{
		return;
	}
	
	//If client == 0 than skip this verifying. It can be an infected or something else without client index.
	if (client != 0)
	{
		if (client == client_attacker)
		{
			return;
		}
	}
	
	player_current_damage[client_attacker] += damage;
	
	if (block_timer[client_attacker])
	{
		return;
	}
	
	CreateTimer(0.01, ShowDamage, client_attacker);
	block_timer[client_attacker] = true;
}

public OnClientConnected(client)
{
	if(!_enable_plugin){
		return;
	}
	//wipe client damage
	trail[client]=-1;
	player_damage[client] = 0;
	block_timer[client] = false;
}

public OnClientDisconnect(client)
{
	if(!_enable_plugin){
		return;
	}
	//wipe client damage
	trail[client]=-1;
	player_damage[client] = 0;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	block_timer[client] = false;
	
	return Plugin_Continue;
}

public Action:ShowTopDefender(Handle:timer)
{
	Show_HUD_MessageALL(str_hud_message);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!_enable_plugin){
		return;
	}
	
	//draw HUD top defender
	if(_top_enable){
		//Show_HUD_MessageALL("Test");
		CreateTimer(3.0, ShowTopDefender);
	}
	
	if(_top_enable && _gift){
		//copy mas
		new player_sort_damage[MAXPLAYERS + 1];
		for (new i = 1; i <= MaxClients; i++){
			player_sort_damage[i]=player_damage[i];
		}
		//sort
		SortIntegers(player_sort_damage, MaxClients, Sort_Descending);
		//colour
		for (new i = 0; i < _top_count; i++)
		{
			if(player_sort_damage[i]!=0)
			{
				for (new client = 1; client <= MaxClients; client++)
				{
					if (player_damage[client]==player_sort_damage[i])
					{
						if (IsClientInGame(client) && GetClientTeam(client) != CS_TEAM_SPEC){
							new String:clientname[32];
							GetClientName(client, clientname, 32);
							int color[4];
							char str_color[11];
							if(i==0){
								SetEntityRenderColor(client, _top_first_r, _top_first_g, _top_first_b, 255);
								color[0]=_trail_first_r;
								color[1]=_trail_first_g;
								color[2]=_trail_first_b;
								Format(str_color, sizeof(str_color), "%i %i %i", color[0], color[1], color[2]);
								TrailSet(client, str_color);
								new Float:currentSpeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
								SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", currentSpeed+_speed_add);
							}
							if(i==1){
								SetEntityRenderColor(client, _top_second_r, _top_second_g, _top_second_b, 255);
								color[0]=_trail_second_r;
								color[1]=_trail_second_g;
								color[2]=_trail_second_b;
								Format(str_color, sizeof(str_color), "%i %i %i", color[0], color[1], color[2]);
								TrailSet(client, str_color);
								new Float:currentSpeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
								SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", currentSpeed+_speed_add);
							}
							if(i==2){
								SetEntityRenderColor(client, _top_third_r, _top_third_g, _top_third_b, 255);
								color[0]=_trail_third_r;
								color[1]=_trail_third_g;
								color[2]=_trail_third_b;
								Format(str_color, sizeof(str_color), "%i %i %i", color[0], color[1], color[2]);
								TrailSet(client, str_color);
								new Float:currentSpeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
								SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", currentSpeed+_speed_add);
							}
							if(i!=0&&i!=1&&i!=2){
								SetEntityRenderColor(client, _top_other_r, _top_other_g, _top_other_b, 255);
								if (_trail_other){
									color[0]=_trail_other_r;
									color[1]=_trail_other_g;
									color[2]=_trail_other_b;
									Format(str_color, sizeof(str_color), "%i %i %i", color[0], color[1], color[2]);
									TrailSet(client, str_color);
								}
							}
						}else{
							player_damage[client]=0;
						}
					}
				}
			}
		}
		//Timer_Handle_Check = CreateTimer(5.0, Check_Human_Alive, _, TIMER_REPEAT);
	}
	//wipe calc damage
	for (new client = 1; client <= MaxClients; client++)
	{
		player_damage[client]=0;
	}
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!_enable_plugin){
		return;
	}
	if(_top_enable){
		CPrintToChatAll("%t","CDN4A Top Defenders");
		Format(str_hud_message, sizeof(str_hud_message), "%t", "CDN4A Top Defenders HUD");
		//copy mas
		new player_sort_damage[MAXPLAYERS + 1];
		for (new i = 1; i <= MaxClients; i++){
			player_sort_damage[i]=player_damage[i];
		}
		//sort
		SortIntegers(player_sort_damage, MaxClients, Sort_Descending);
		//say top
		for (new i = 0; i < _top_count; i++)
		{
			if(player_sort_damage[i]!=0)
			{
				for (new client = 1; client <= MaxClients; client++)
				{
					if (player_damage[client]==player_sort_damage[i])
					{
						new String:clientname[32];
						GetClientName(client, clientname, 32);
						if(i==0){
							CPrintToChatAll("%t","CDN4A Top First",i+1,client,player_damage[client]);
						}
						if(i==1){
							CPrintToChatAll("%t","CDN4A Top Second",i+1,client,player_damage[client]);
						}
						if(i==2){
							CPrintToChatAll("%t","CDN4A Top Third",i+1,client,player_damage[client]);
						}
						if(i!=0&&i!=1&&i!=2){
							CPrintToChatAll("%t","CDN4A Top Other",i+1,client,player_damage[client]);
						}
						Format(str_hud_message, sizeof(str_hud_message), "%s\n%t", str_hud_message, "CDN4A Top Name HUD", i+1,client,player_damage[client]);
					}
				}
			} else
			{
			CPrintToChatAll("%t","CDN4A none",i+1);
			Format(str_hud_message, sizeof(str_hud_message), "%s\n%t", str_hud_message, "CDN4A none HUD",i+1);
			}
		}
		//show hud
		Format(str_hud_message, sizeof(str_hud_message), "%s\n%t", str_hud_message, "CDN4A lastline HUD");
		//Show_HUD_MessageALL(str_hud_message);
		if(_gift)
		{
			for (new client = 1; client <= MaxClients; client++)
			{
				trail[client]=-1;
			}
			//KillTimer(Timer_Handle_Check);
		}
	}
}

public Show_HUD_MessageALL(char[] message)
{
    new Handle:hHudText = CreateHudSynchronizer();
    SetHudTextParams(-1.0, 0.35, 5.0, 50, 205, 50, 255, 2, 1.0, 0.02, 0.05);
    for (new client = 1; client <= MaxClients; client++)
    {
        if (IsValidClient(client) && IsClientInGame(client) && (IsFakeClient(client) == false))
        {
            ShowSyncHudText(client, hHudText, message);
        }
    }
    CloseHandle(hHudText);
} 

stock bool:IsValidClient(client) 
{ 
	if (client > 0 && client <= MaxClients && IsValidEdict(client)) return true; 
	return false; 
}

//kill trail on death
public Action:Check_Human_Alive(Handle:timer)
{
	if(_gift)
	{
		for (new client = 1; client <= MaxClients; client++)
		{  
			if (IsValidClient(client) && IsClientInGame(client) && ((GetClientTeam(client) <= 2) || (IsPlayerAlive(client) == false)))
			{
				if(trail[client] != -1)
				{
					AcceptEntityInput(trail[client], "Kill");//kill trail
					SetEntityRenderColor(client, 255, 255, 255, 255);//change color
					trail[client]=-1;
				}
			}
		}
	}
	return Plugin_Continue;
}

public TrailSet(client, char[] color)
{
	if(IsValidClient(client) && IsClientInGame(client) && (GetClientTeam(client) != 1) && IsPlayerAlive(client))
	{
		new size = GetArraySize(g_Arraysprite);
		if (!size)
		{
			return;
		}
		new String:sprite_filename[PLATFORM_MAX_PATH];
		GetArrayString(g_Arraysprite, GetRandomInt(0, size-1),sprite_filename,sizeof(sprite_filename));	
		//LogError("[Debug-array] %s",sprite_filename);
		new Float:Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 95.0;
		trail[client] = CreateEntityByName("env_sprite");
		if (trail[client] < 1)
		{
			LogError("env_sprite create error!");
			return;
		}
		DispatchKeyValueVector(trail[client], "origin", Pos);
		decl String:oldName[128];
		GetEntPropString(client, Prop_Data, "m_iName", oldName, sizeof(oldName));
		decl String:xName[10];
		IntToString(client, xName, 10);
		decl String:c_rendermode[3];
		IntToString(_trail_rendermode, c_rendermode, 3);
		decl String:c_alpha[4];
		IntToString(_trail_alpha, c_alpha, 4);
		
		DispatchKeyValue(client, "targetname", xName);
		DispatchKeyValue(trail[client], "model", sprite_filename);
		DispatchKeyValue(trail[client], "rendermode", c_rendermode);
		DispatchKeyValue(trail[client], "rendercolor", color);
		DispatchKeyValue(trail[client], "renderamt", c_alpha);
		DispatchKeyValue(trail[client], "spawnflags", "1");
		DispatchKeyValue(trail[client], "scale", "0.1");
		DispatchSpawn(trail[client]);
		SetVariantString(xName);
		AcceptEntityInput(trail[client], "SetParent");
		//AcceptEntityInput(trail[client], "ShowSprite");
		//fix spritetrail CS GO
		//SetVariantString("OnUser1 !self:SetScale:1:0.5:-1");
		//AcceptEntityInput(trail[client], "AddOutput");
		//AcceptEntityInput(trail[client], "FireUser1");
		DispatchKeyValue(client, "targetname", oldName);
	}
}

public Refresh_cvar(){
	_enable_plugin=GetConVarBool(cvar_cash_damage_enable);
	_damage_div=GetConVarInt(cvar_damage_div);
	_top_enable=GetConVarBool(cvar_top_enable);
	_top_count=GetConVarInt(cvar_damage_top);
	_gift=GetConVarBool(cvar_damage_rewarding_top);
	_cash_add=GetConVarBool(cvar_damage_cash_add);

	_top_first_r=GetConVarInt(cvar_top_first_r);
	_top_first_g=GetConVarInt(cvar_top_first_g);
	_top_first_b=GetConVarInt(cvar_top_first_b);

	_top_second_r=GetConVarInt(cvar_top_second_r);
	_top_second_g=GetConVarInt(cvar_top_second_g);
	_top_second_b=GetConVarInt(cvar_top_second_b);

	_top_third_r=GetConVarInt(cvar_top_third_r);
	_top_third_g=GetConVarInt(cvar_top_third_g);
	_top_third_b=GetConVarInt(cvar_top_third_b);

	_top_other_r=GetConVarInt(cvar_top_other_r);
	_top_other_g=GetConVarInt(cvar_top_other_g);
	_top_other_b=GetConVarInt(cvar_top_other_b);

	_trail_first_r=GetConVarInt(cvar_trail_first_r);
	_trail_first_g=GetConVarInt(cvar_trail_first_g);
	_trail_first_b=GetConVarInt(cvar_trail_first_b);

	_trail_second_r=GetConVarInt(cvar_trail_second_r);
	_trail_second_g=GetConVarInt(cvar_trail_second_g);
	_trail_second_b=GetConVarInt(cvar_trail_second_b);

	_trail_third_r=GetConVarInt(cvar_trail_third_r);
	_trail_third_g=GetConVarInt(cvar_trail_third_g);
	_trail_third_b=GetConVarInt(cvar_trail_third_b);

	_trail_other=GetConVarBool(cvar_trail_other_enable);
	_trail_other_r=GetConVarInt(cvar_trail_other_r);
	_trail_other_g=GetConVarInt(cvar_trail_other_g);
	_trail_other_b=GetConVarInt(cvar_trail_other_b);

	_trail_rendermode=GetConVarInt(cvar_trail_rendermode);
	_trail_alpha=GetConVarInt(cvar_trail_alpha);

	_speed_add=GetConVarFloat(cvar_speed);
}

public Action:Refresh_cvar_admin(client, args){
	Refresh_cvar();
	if(IsValidClient(client)){
		CPrintToChat(client, "%t", "CDN4A Refresh CVAR");
	}
	if(client==0){
		LogMessage("[ZR] Cash Damage CVAR's Refresh");
	}
}

public Action:DeleteTrail(client, args)
{
	if(_gift)
	{
		if (IsValidClient(client))
		{
			if(trail[client] != -1)
			{
				CPrintToChat(client, "%t", "CDN4A Trail Delete");
				AcceptEntityInput(trail[client], "Kill");//kill trail
				SetEntityRenderColor(client, 255, 255, 255, 255);//change color
				trail[client]=-1;
			}else{
				CPrintToChat(client, "%t", "CDN4A No Trail");
			}
		}
	}
}
