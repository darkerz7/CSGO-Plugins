#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <csgocolors_fix>
#include <zombiereloaded>

//uncomment the next line to integrate store plugin and configure function names
//#define SHOP

#if defined SHOP
#include <shop>
#define SHOP_SET_CREDITS_FUNC Shop_SetClientCredits
#define SHOP_GET_CREDITS_FUNC Shop_GetClientCredits
#endif

#define CS_TEAM_T 2
#define CS_TEAM_CT 3

//cvars
ConVar	cvar_Enable,
		cvar_TopCount,
		cvar_Perk,
		cvar_CashDiv,
		cvar_TopInfector,
		cvar_InfectorCount,
		cvar_InfectorPerk,
		cvar_Immunity,
		cvar_MinPlayers,
		cvar_MaxMoney,
		cvar_ShowDamage,
		cvar_MinPlPerk;

float	g_fCashDiv = 20.0;
int		g_iMaxMoney = 16000;

bool	g_bEnable = true;
bool	g_bShowDamage = true;
int		g_iTopCount = 3;
bool	g_bPerk = true;

bool	g_bInfectorEnable = true;
int		g_iInfectorTopCount = 3;
bool	g_bInfectorPerk = true;

int g_iCash = -1;

int g_iPlayerDamage[MAXPLAYERS+1] = 0;
int g_iPlayerKill[MAXPLAYERS+1] = 0;
int g_iPlayerInfect[MAXPLAYERS+1] = 0;

int g_iTopNextRound[MAXPLAYERS+1] = 0;
int g_iPlayerCurrentDamage[MAXPLAYERS+1] = 0;
bool g_bBlockTimer[MAXPLAYERS+1] = {false,...};

#if defined SHOP
int Config_Defender_Shop[4];
#endif
bool Config_Defender_Immunity[3];
float Config_Defender_Speed[4];
float Config_Defender_Gravity[4];
int Config_Defender_Perk_Type[4]; //0 - None, 1 - Sprite, 2 - Trail, 3 - Model
int Config_Defender_Perk_Color[4][4];
int Config_Defender_RenderMode[4];
float Config_Defender_Trail_Config[4][3];
Handle Config_Defender_Perk_List[4];

#if defined SHOP
int Config_Infector_Shop[4];
#endif
bool Config_Infector_Immunity[3];
float Config_Infector_Speed[4];
float Config_Infector_Gravity[4];
int Config_Infector_Perk_Type[4]; //0 - None, 1 - Sprite, 2 - Trail, 3 - Model
int Config_Infector_Perk_Color[4][4];
int Config_Infector_RenderMode[4];
float Config_Infector_Trail_Config[4][3];
Handle Config_Infector_Perk_List[4];

int Config_HUD_Defender_Color[4] = {50,205,50,255};
float Config_HUD_Defender_x = -1.0;
float Config_HUD_Defender_y = 0.35;

int Config_HUD_Infector_Color[4] = {255,100,50,255};
float Config_HUD_Infector_x = -1.0;
float Config_HUD_Infector_y = 0.55;

Handle 	g_hHudDefender,
		g_hHudInfector;

int g_iEntityPerk[MAXPLAYERS+1] = -1;

bool Cfg_Loaded = false;

bool g_bImmunity[MAXPLAYERS+1] = {false,...};
int g_iChance = 100;
int g_iMinPlayersImmunity = 15;
int g_iInfectedChance = 0;
int g_iMinPlayersPerk = 10;

bool g_bWarmUp = false;

public Plugin myinfo = 
{
	name = "[ZR] TopDefenders with Perk CS:GO",
	author = "DarkerZ [RUS]",
	description = "Shows damage by zombies and gives perk for the top",
	version = "2.3.1",
	url = "dark-skill.ru"
}

public void OnPluginStart()
{
	LoadTranslations("topdefenders_perk.phrases");
	
	g_iCash = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iCash == -1)
	{
		SetFailState("[CS:GO] Give Cash - Failed to find offset for m_iAccount!");
	}
	
	for(int i=0; i<4;i++)
	{
		Config_Defender_Perk_List[i] = CreateArray(PLATFORM_MAX_PATH);
		Config_Infector_Perk_List[i] = CreateArray(PLATFORM_MAX_PATH);
	}
	
	cvar_Enable = CreateConVar("sm_topdefenders_enable", "1", "[TopDefenders] Enable plugin", _, true, 0.0, true, 1.0);
	cvar_TopCount = CreateConVar("sm_topdefenders_topcount", "3", "[TopDefenders] Count top on round end (min 3/max 15)", _, true, 3.0, true, 15.0);
	cvar_Perk = CreateConVar("sm_topdefenders_perk", "1", "[TopDefenders] Gives perk for the top", _, true, 0.0, true, 1.0);
	cvar_CashDiv = CreateConVar("sm_topdefenders_cashdiv", "20", "[TopDefenders] Divider (min 0/max 50; 0 - Disable)", _, true, 0.0, true, 50.0);
	cvar_ShowDamage = CreateConVar("sm_topdefenders_showdamage", "1", "[TopDefenders] Enable Show Damage Addon", _, true, 0.0, true, 1.0);
	
	cvar_TopInfector = CreateConVar("sm_topdefenders_infectors_enable", "1", "[TopDefenders] Enable Top Infector Addon", _, true, 0.0, true, 1.0);
	cvar_InfectorCount = CreateConVar("sm_topdefenders_infectors_topcount", "3", "[TopDefenders] Count top Infector on round end (min 3/max 15)", _, true, 3.0, true, 15.0);
	cvar_InfectorPerk = CreateConVar("sm_topdefenders_infectors_perk", "1", "[TopDefenders] Gives Infector perk for the top", _, true, 0.0, true, 1.0);
	cvar_Immunity = CreateConVar("sm_topdefenders_immunity_chance", "100", "[TopDefenders] Immunity Chance", _, true, 0.0, true, 100.0);
	cvar_MinPlayers = CreateConVar("sm_topdefenders_immunity_minplayers", "15", "[TopDefenders] Minimum players for immunity", _, true, 10.0, true, 64.0);
	cvar_MinPlPerk = CreateConVar("sm_topdefenders_perk_minplayers", "10", "[TopDefenders] Minimum players for give Perk and Credits", _, true, 1.0, true, 64.0);
	cvar_MaxMoney = FindConVar("mp_maxmoney");
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	HookConVarChange(cvar_Enable, Cvar_Changed);
	HookConVarChange(cvar_TopCount, Cvar_Changed);
	HookConVarChange(cvar_Perk, Cvar_Changed);
	HookConVarChange(cvar_CashDiv, Cvar_Changed);
	HookConVarChange(cvar_ShowDamage, Cvar_Changed);
	
	HookConVarChange(cvar_TopInfector, Cvar_Changed);
	HookConVarChange(cvar_InfectorCount, Cvar_Changed);
	HookConVarChange(cvar_InfectorPerk, Cvar_Changed);
	HookConVarChange(cvar_Immunity, Cvar_Changed);
	HookConVarChange(cvar_MinPlayers, Cvar_Changed);
	HookConVarChange(cvar_MaxMoney, Cvar_Changed);
	HookConVarChange(cvar_MinPlPerk, Cvar_Changed);
	
	RegConsoleCmd("sm_pr", PerkRemove, "[TopDefender] Remove Perk from yourself");
	
	RegAdminCmd("sm_topdefenders_config_test1", ConfigTest_Defenders, ADMFLAG_ROOT, "[TopDefenders] Config Test Defenders");
	RegAdminCmd("sm_topdefenders_config_test2", ConfigTest_Infectors, ADMFLAG_ROOT, "[TopDefenders] Config Test Infectors");
	RegAdminCmd("sm_topdefenders_refresh", ConfigRefresh, ADMFLAG_CONVARS, "[TopDefenders] Refresh Config");
	
	AutoExecConfig(true, "topdefenders_perk");
	
	g_hHudDefender = CreateHudSynchronizer();
	g_hHudInfector = CreateHudSynchronizer();
}

public void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==cvar_Enable)
		g_bEnable = GetConVarBool(convar);
	if(convar==cvar_TopCount)
		g_iTopCount = GetConVarInt(convar);
	if(convar==cvar_Perk)
		g_bPerk = GetConVarBool(convar);
	if(convar==cvar_CashDiv)
		g_fCashDiv = GetConVarFloat(convar);
	if(convar==cvar_TopInfector)
		g_bInfectorEnable = GetConVarBool(convar);
	if(convar==cvar_InfectorCount)
		g_iInfectorTopCount = GetConVarInt(convar);
	if(convar==cvar_InfectorPerk)
		g_bInfectorPerk = GetConVarBool(convar);
	if(convar==cvar_Immunity)
		g_iChance = GetConVarInt(convar);
	if(convar==cvar_MinPlayers)
		g_iMinPlayersImmunity = GetConVarInt(convar);
	if(convar==cvar_MaxMoney)
		g_iMaxMoney = GetConVarInt(convar);
	if(convar==cvar_ShowDamage)
		g_bShowDamage = GetConVarBool(convar);
	if(convar==cvar_MinPlPerk)
		g_iMinPlayersPerk = GetConVarInt(convar);
}

public void OnMapStart()
{
	AddToDownload();
	Cfg_Loaded = false;
	ReloadCfgFile();
	CreateTimer(5.0, Check_Human_Alive, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client)
{
	if(!g_bEnable) return;
	//wipe client
	g_iPlayerDamage[client] = 0;
	g_iPlayerKill[client] = 0;
	g_iPlayerInfect[client] = 0;
	g_bBlockTimer[client] = false;
	g_iTopNextRound[client] = 0;
	g_iEntityPerk[client] = -1;
	g_bImmunity[client] = false;
}

public void OnClientDisconnect(int client)
{
	if(!g_bEnable) return;
	//wipe client
	g_iPlayerDamage[client] = 0;
	g_iPlayerKill[client] = 0;
	g_iPlayerInfect[client] = 0;
	g_iTopNextRound[client] = 0;
	g_iEntityPerk[client] = -1;
	g_bImmunity[client] = false;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable) return;
	
	if (GameRules_GetProp("m_bWarmupPeriod") == 1) g_bWarmUp = true;
	else if (GameRules_GetProp("m_bWarmupPeriod") == 0) g_bWarmUp = false;
	
	if(g_bWarmUp) return;
	
	g_iInfectedChance = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		g_bImmunity[client] = false;
	}
	int iIngamePlayers = GetIngamePlayers();
	if(g_bPerk && iIngamePlayers >= g_iMinPlayersPerk) GivePerk_TopDefender();
	if(g_bInfectorEnable && g_bInfectorPerk && iIngamePlayers >= g_iMinPlayersPerk) GivePerk_TopInfector();
	
	//wipe clients
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsValidEdict(client) && IsClientInGame(client))
			SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		g_iPlayerDamage[client] = 0;
		g_iPlayerKill[client] = 0;
		g_iPlayerInfect[client] = 0;
		g_iTopNextRound[client] = 0;
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable) return;
	
	if(g_bWarmUp)
	{
		//wipe clients
		for (int client = 1; client <= MaxClients; client++)
		{
			if(IsValidEdict(client) && IsClientInGame(client))
				SetEntProp(client, Prop_Data, "m_iDeaths", 0);
			g_iPlayerDamage[client] = 0;
			g_iPlayerKill[client] = 0;
			g_iPlayerInfect[client] = 0;
			g_iTopNextRound[client] = 0;
		}
		return;
	}
	
	char sHUD[4096] = "";
	CPrintToChatAll("%t", "Chat Top Defenders");
	FormatEx(sHUD, sizeof(sHUD), "%t", "HUD Top Defenders");
	//copy
	int iSortDamage[MAXPLAYERS + 1];
	for (int i = 1; i <= MaxClients; i++)
	{
		iSortDamage[i] = g_iPlayerDamage[i];
	}
	//sort
	SortIntegers(iSortDamage, MaxClients+1, Sort_Descending);
	int iCount = 0;
	int iSDindex = 0;
	int iIgnoreLast = 0;
	bool bMasNoEnd = true;
	while(iCount<g_iTopCount)
	{
		if(iSortDamage[iSDindex]!=0 && bMasNoEnd)
		{
			if(iSortDamage[iSDindex]!=iIgnoreLast)
			{
				iIgnoreLast = iSortDamage[iSDindex];
				for (int i = 1; i <= MaxClients; i++)
				{
					if (g_iPlayerDamage[i]==iSortDamage[iSDindex])
					{
						iCount++;
						char clientname[32];
						GetClientName(i, clientname, sizeof(clientname));
						if(iCount==1) CPrintToChatAll("%t", "Chat Top DefFirst",iCount, i, g_iPlayerDamage[i]);
						if(iCount==2) CPrintToChatAll("%t", "Chat Top DefSecond",iCount, i, g_iPlayerDamage[i]);
						if(iCount==3) CPrintToChatAll("%t", "Chat Top DefThird",iCount, i, g_iPlayerDamage[i]);
						if((iCount!=1)&&(iCount!=2)&&(iCount!=3)) CPrintToChatAll("%t", "Chat Top DefOther",iCount, i, g_iPlayerDamage[i]);
						Format(sHUD, sizeof(sHUD), "%s\n%t", sHUD, "HUD Top DefPosition", iCount, i, g_iPlayerDamage[i]);
						g_iTopNextRound[i]=iCount;
					}
					if(iCount==g_iTopCount) break;
				}
			}
			if(iSDindex<MaxClients) iSDindex++;
			else bMasNoEnd = false;
		}else
		{
			iCount++;
			CPrintToChatAll("%t", "Chat Top DefNone", iCount);
			Format(sHUD, sizeof(sHUD), "%s\n%t", sHUD, "HUD Top DefNone", iCount);
		}
	}
	SetHudTextParams(Config_HUD_Defender_x, Config_HUD_Defender_y, 10.0, Config_HUD_Defender_Color[0], Config_HUD_Defender_Color[1], Config_HUD_Defender_Color[2], Config_HUD_Defender_Color[3], 0, 1.0, 0.02, 0.05);
	#if defined SHOP
	int iPlayers = GetIngamePlayers();
	#endif
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsClientInGame(i) && (IsFakeClient(i) == false))
		{
			#if defined SHOP
			if(iPlayers>=g_iMinPlayersPerk && g_iTopNextRound[i]>0)
			{
				int iPlace=g_iTopNextRound[i]-1;
				if(iPlace>3) iPlace=3;
				if(Config_Defender_Shop[iPlace]>0)
				{
					CPrintToChat(i, "%t", "Chat Give Credits Defenders", Config_Defender_Shop[iPlace], g_iTopNextRound[i]);
					SHOP_SET_CREDITS_FUNC(i, SHOP_GET_CREDITS_FUNC(i)+Config_Defender_Shop[iPlace]);
				}
			}
			#endif
			ShowSyncHudText(i, g_hHudDefender, sHUD);
		}
	}
	
	if(g_bInfectorEnable)
	{
		CPrintToChatAll("%t", "Chat Top Infectors");
		FormatEx(sHUD, sizeof(sHUD), "%t", "HUD Top Infectors");
		//copy
		for (int i = 1; i <= MaxClients; i++)
		{
			iSortDamage[i] = g_iPlayerInfect[i];
		}
		//sort
		SortIntegers(iSortDamage, MaxClients+1, Sort_Descending);
		iCount = 0;
		iSDindex = 0;
		iIgnoreLast = 0;
		bMasNoEnd = true;
		while(iCount<g_iInfectorTopCount)
		{
			if(iSortDamage[iSDindex]!=0 && bMasNoEnd)
			{
				if(iSortDamage[iSDindex]!=iIgnoreLast)
				{
					iIgnoreLast = iSortDamage[iSDindex];
					for (int i = 1; i <= MaxClients; i++)
					{
						if (g_iPlayerInfect[i]==iSortDamage[iSDindex])
						{
							iCount++;
							char clientname[32];
							GetClientName(i, clientname, sizeof(clientname));
							if(iCount==1) CPrintToChatAll("%t", "Chat Top InfFirst", iCount, i, g_iPlayerInfect[i]);
							if(iCount==2) CPrintToChatAll("%t", "Chat Top InfSecond", iCount, i, g_iPlayerInfect[i]);
							if(iCount==3) CPrintToChatAll("%t", "Chat Top InfThird", iCount, i, g_iPlayerInfect[i]);
							if((iCount!=1)&&(iCount!=2)&&(iCount!=3)) CPrintToChatAll("%t", "Chat Top InfOther", iCount, i, g_iPlayerInfect[i]);
							Format(sHUD, sizeof(sHUD), "%s\n%t", sHUD, "HUD Top InfPosition", iCount, i, g_iPlayerInfect[i]);
							g_iTopNextRound[i]=-iCount;
						}
						if(iCount==g_iInfectorTopCount) break;
					}
				}
				if(iSDindex<MaxClients) iSDindex++;
				else bMasNoEnd = false;
			}else
			{
				iCount++;
				CPrintToChatAll("%t", "Chat Top InfNone", iCount);
				Format(sHUD, sizeof(sHUD), "%s\n%t", sHUD, "HUD Top InfNone", iCount);
			}
		}
		SetHudTextParams(Config_HUD_Infector_x, Config_HUD_Infector_y, 10.0, Config_HUD_Infector_Color[0], Config_HUD_Infector_Color[1], Config_HUD_Infector_Color[2], Config_HUD_Infector_Color[3], 0, 1.0, 0.02, 0.05);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i) && IsClientInGame(i) && (IsFakeClient(i) == false))
			{
				#if defined SHOP
				if(iPlayers>=g_iMinPlayersPerk && g_iTopNextRound[i]<0)
				{
					int iPlace=-g_iTopNextRound[i]-1;
					if(iPlace>3) iPlace=3;
					if(Config_Infector_Shop[iPlace]>0)
					{
						CPrintToChat(i, "%t", "Chat Give Credits Infectors", Config_Infector_Shop[iPlace], -g_iTopNextRound[i]);
						SHOP_SET_CREDITS_FUNC(i, SHOP_GET_CREDITS_FUNC(i)+Config_Infector_Shop[iPlace]);
					}
				}
				#endif
				ShowSyncHudText(i, g_hHudInfector, sHUD);
			}
		}
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bBlockTimer[client] = false;
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable||!g_bShowDamage) return;
	int client  = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker) && IsValidClient(client) && IsClientInGame(attacker))
		if(!IsFakeClient(attacker) && IsClientInGame(attacker) && IsClientInGame(client) && (attacker != client))
		{
			if((GetClientTeam(attacker) == CS_TEAM_CT) && (GetClientTeam(client) == CS_TEAM_T))
			{
				g_iPlayerKill[attacker]++;
			}
		}
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_bEnable) return;
	int client  = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker) && IsValidClient(client))
		if(!IsFakeClient(attacker) && IsClientInGame(attacker) && (attacker != client))
		{
			if(GetClientTeam(attacker) == CS_TEAM_CT)
			{
				int iDmg = GetEventInt(event, "dmg_health");
				g_iPlayerDamage[attacker]+= iDmg;
				SetEntProp(attacker, Prop_Data, "m_iDeaths", g_iPlayerDamage[attacker]/1000);
				if(g_bShowDamage) CalcDamage(attacker, iDmg);
				if(g_fCashDiv>0.0)
				{
					int iCurrentCash = GetEntData(attacker, g_iCash);
					int iAddCash = iCurrentCash + RoundFloat(iDmg / g_fCashDiv);
					if(iAddCash > g_iMaxMoney) iAddCash=g_iMaxMoney;
					SetEntData(attacker, g_iCash, iAddCash);
				}
			}
		}
}

void CalcDamage(int attacker, int iDmg)
{	
	if (!IsClientInGame(attacker)) return;
	
	g_iPlayerCurrentDamage[attacker]+= iDmg;
	
	if (g_bBlockTimer[attacker]) return;
	
	CreateTimer(0.01, ShowDamageHuman, attacker);
	g_bBlockTimer[attacker] = true;
}

public Action ShowDamageHuman(Handle timer, any client)
{
	g_bBlockTimer[client] = false;
	if(IsValidClient(client) && IsClientInGame(client))
	{
		PrintHintText(client, "%t", "Hint Damage", g_iPlayerCurrentDamage[client], g_iPlayerKill[client], g_iPlayerDamage[client]);
		g_iPlayerCurrentDamage[client] = 0;
	}
}

public void GivePerk_TopDefender()
{
	if(Cfg_Loaded)
		for(int i=1;i<=g_iTopCount;i++)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if(g_iTopNextRound[client] == i)
				{
					if(IsValidEdict(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)))
					{
						//code perk
						int iPlace=i-1;
						if(iPlace>3) iPlace = 3;
						//immunity
						if(iPlace<3) if(Config_Defender_Immunity[iPlace] == true) g_bImmunity[client] = true;
						//speed
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")+Config_Defender_Speed[iPlace]);
						//gravity
						SetEntityGravity(client, GetEntityGravity(client)-Config_Defender_Gravity[iPlace]);
						if(Config_Defender_Perk_Type[iPlace]==1) SpriteSet(client, iPlace, true);
							else if(Config_Defender_Perk_Type[iPlace]==2) TrailSet(client, iPlace, true);
								else if(Config_Defender_Perk_Type[iPlace]==3) ModelSet(client, iPlace, true);
					}
					g_iTopNextRound[client]=0;
					break;
				}
			}
		}
}

public void GivePerk_TopInfector()
{
	if(Cfg_Loaded)
		for(int i=1;i<=g_iInfectorTopCount;i++)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if(g_iTopNextRound[client] == -i)
				{
					if(IsValidEdict(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)))
					{
						//code perk
						int iPlace=i-1;
						if(iPlace>3) iPlace = 3;
						//immunity
						if(iPlace<3) if(Config_Infector_Immunity[iPlace] == true) g_bImmunity[client] = true;
						//speed
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")+Config_Infector_Speed[iPlace]);
						//gravity
						SetEntityGravity(client, GetEntityGravity(client)-Config_Infector_Gravity[iPlace]);
						if(Config_Infector_Perk_Type[iPlace]==1) SpriteSet(client, iPlace, false);
							else if(Config_Infector_Perk_Type[iPlace]==2) TrailSet(client, iPlace, false);
								else if(Config_Infector_Perk_Type[iPlace]==3) ModelSet(client, iPlace, false);
					}
					g_iTopNextRound[client]=0;
					break;
				}
			}
		}
}

public void SpriteSet(int client, int iPlace, bool bDefender)
{
	if(IsValidClient(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)) && IsPlayerAlive(client))
	{
		char filename[PLATFORM_MAX_PATH];
		char cRenderMode[3];
		char cAlpha[4];
		char cColor[11];
		if(bDefender)
		{
			int iSize = GetArraySize(Config_Defender_Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(Config_Defender_Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(Config_Defender_RenderMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", Config_Defender_Perk_Color[iPlace][0], Config_Defender_Perk_Color[iPlace][1], Config_Defender_Perk_Color[iPlace][2]);
			IntToString(Config_Defender_Perk_Color[iPlace][3], cAlpha, 4);
		}else
		{
			int iSize = GetArraySize(Config_Infector_Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(Config_Infector_Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(Config_Infector_RenderMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", Config_Infector_Perk_Color[iPlace][0], Config_Infector_Perk_Color[iPlace][1], Config_Infector_Perk_Color[iPlace][2]);
			IntToString(Config_Infector_Perk_Color[iPlace][3], cAlpha, 4);
		}
		float Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 95.0;
		g_iEntityPerk[client] = CreateEntityByName("env_sprite");
		if (g_iEntityPerk[client] < 1)
		{
			LogError("env_sprite create error!");
			return;
		}
		DispatchKeyValueVector(g_iEntityPerk[client], "origin", Pos);
		
		DispatchKeyValue(g_iEntityPerk[client], "model", filename);
		DispatchKeyValue(g_iEntityPerk[client], "rendermode", cRenderMode);
		DispatchKeyValue(g_iEntityPerk[client], "rendercolor", cColor);
		DispatchKeyValue(g_iEntityPerk[client], "renderamt", cAlpha);
		DispatchKeyValue(g_iEntityPerk[client], "spawnflags", "1");
		DispatchKeyValue(g_iEntityPerk[client], "scale", "0.1");
		DispatchSpawn(g_iEntityPerk[client]);
		SetVariantString("!activator");
		AcceptEntityInput(g_iEntityPerk[client], "SetParent", client);
	}
}

public void TrailSet(int client, int iPlace, bool bDefender)
{
	if(IsValidClient(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)) && IsPlayerAlive(client))
	{
		char filename[PLATFORM_MAX_PATH];
		char cRenderMode[3];
		char cAlpha[4];
		char cColor[11];
		float 	fLifeTime,
				fWidthStart,
				fWidthEnd;
		if(bDefender)
		{
			int iSize = GetArraySize(Config_Defender_Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(Config_Defender_Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(Config_Defender_RenderMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", Config_Defender_Perk_Color[iPlace][0], Config_Defender_Perk_Color[iPlace][1], Config_Defender_Perk_Color[iPlace][2]);
			IntToString(Config_Defender_Perk_Color[iPlace][3], cAlpha, 4);
			fLifeTime = Config_Defender_Trail_Config[iPlace][0];
			fWidthStart = Config_Defender_Trail_Config[iPlace][1];
			fWidthEnd = Config_Defender_Trail_Config[iPlace][2];
		}else
		{
			int iSize = GetArraySize(Config_Infector_Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(Config_Infector_Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(Config_Infector_RenderMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", Config_Infector_Perk_Color[iPlace][0], Config_Infector_Perk_Color[iPlace][1], Config_Infector_Perk_Color[iPlace][2]);
			IntToString(Config_Infector_Perk_Color[iPlace][3], cAlpha, 4);
			fLifeTime = Config_Infector_Trail_Config[iPlace][0];
			fWidthStart = Config_Infector_Trail_Config[iPlace][1];
			fWidthEnd = Config_Infector_Trail_Config[iPlace][2];
		}
		float Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 10.0;
		g_iEntityPerk[client] = CreateEntityByName("env_spritetrail");
		if (g_iEntityPerk[client] < 1)
		{
			LogError("env_spritetrail create error!");
			return;
		}
		SetEntPropFloat(g_iEntityPerk[client], Prop_Send, "m_flTextureRes", 0.05);
		DispatchKeyValueVector(g_iEntityPerk[client], "origin", Pos);
		
		DispatchKeyValue(g_iEntityPerk[client], "spritename", filename);
		DispatchKeyValue(g_iEntityPerk[client], "rendermode", cRenderMode);
		DispatchKeyValue(g_iEntityPerk[client], "rendercolor", cColor);
		DispatchKeyValue(g_iEntityPerk[client], "renderamt", cAlpha);
		DispatchKeyValueFloat(g_iEntityPerk[client], "lifetime", fLifeTime);
		DispatchKeyValueFloat(g_iEntityPerk[client], "startwidth", fWidthStart);
		DispatchKeyValueFloat(g_iEntityPerk[client], "endwidth", fWidthEnd);
		DispatchSpawn(g_iEntityPerk[client]);
		SetVariantString("!activator");
		AcceptEntityInput(g_iEntityPerk[client], "SetParent", client);
		AcceptEntityInput(g_iEntityPerk[client], "ShowSprite");
		//fix spritetrail CS GO
		SetVariantString("OnUser1 !self:SetScale:1:0.5:-1");
		AcceptEntityInput(g_iEntityPerk[client], "AddOutput");
		AcceptEntityInput(g_iEntityPerk[client], "FireUser1");
	}
}

public void ModelSet(int client, int iPlace, bool bDefender)
{
	if(IsValidClient(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)) && IsPlayerAlive(client))
	{
		char filename[PLATFORM_MAX_PATH];
		char cRenderMode[3];
		char cColor[11];
		if(bDefender)
		{
			int iSize = GetArraySize(Config_Defender_Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(Config_Defender_Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(Config_Defender_RenderMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", Config_Defender_Perk_Color[iPlace][0], Config_Defender_Perk_Color[iPlace][1], Config_Defender_Perk_Color[iPlace][2]);
		}else
		{
			int iSize = GetArraySize(Config_Infector_Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(Config_Infector_Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(Config_Infector_RenderMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", Config_Infector_Perk_Color[iPlace][0], Config_Infector_Perk_Color[iPlace][1], Config_Infector_Perk_Color[iPlace][2]);
		}
		float Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 85.0;
		g_iEntityPerk[client] = CreateEntityByName("prop_dynamic");
		if (g_iEntityPerk[client] < 1)
		{
			LogError("prop_dynamic create error!");
			return;
		}
		DispatchKeyValueVector(g_iEntityPerk[client], "origin", Pos);
		
		DispatchKeyValue(g_iEntityPerk[client], "spawnflags", "256");
		DispatchKeyValue(g_iEntityPerk[client], "solid", "0");
		DispatchKeyValue(g_iEntityPerk[client], "DisableShadows", "1");
		DispatchKeyValue(g_iEntityPerk[client], "model", filename);
		DispatchKeyValue(g_iEntityPerk[client], "rendermode", cRenderMode);
		DispatchKeyValue(g_iEntityPerk[client], "rendercolor", cColor);
		DispatchKeyValue(g_iEntityPerk[client], "renderamt", "254");
		DispatchSpawn(g_iEntityPerk[client]);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_iEntityPerk[client], "SetParent", client);
		AcceptEntityInput(g_iEntityPerk[client], "TurnOn", g_iEntityPerk[client], g_iEntityPerk[client], 0);
	}
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if(!g_bEnable) return Plugin_Continue;
	if(motherInfect && g_bImmunity[client] && GetRandomInt(0, 100) <= g_iChance)
	{
		if(GetIngamePlayers()<g_iMinPlayersImmunity) return Plugin_Continue;
		++g_iInfectedChance;
		Handle dPack;
		CreateDataTimer(g_iInfectedChance * 0.1, Rescued, dPack);
		WritePackCell(dPack, client);
		WritePackCell(dPack, respawnOverride);
		WritePackCell(dPack, respawn);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public int GetIngamePlayers()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{  
		if (IsClientInGame(i) && IsPlayerAlive(i)) iCount++;
	}
	return iCount;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(!g_bEnable) return;
	if(!motherInfect && IsValidClient(attacker) && IsValidClient(client))
		if(!IsFakeClient(attacker) && IsClientInGame(attacker) && (attacker != client))
		{
			g_iPlayerInfect[attacker]++;
			SetEntProp(attacker, Prop_Data, "m_iDeaths", g_iPlayerInfect[attacker]);
			if(g_bShowDamage) PrintHintText(attacker, "%t", "Hint Infect", client, g_iPlayerInfect[attacker]);
		}
}

public Action Rescued(Handle timer, Handle dPack)
{
	int client;
	Handle respawnOverride;
	Handle respawn;
	
	ResetPack(dPack);
	client = ReadPackCell(dPack);
	respawnOverride = ReadPackCell(dPack);
	respawn = ReadPackCell(dPack);
	if(!IsClientInGame(client) && !IsPlayerAlive(client)) return;
	int iInfected = FindNewInfected(client);
	if(iInfected) 
	{
		ZR_InfectClient(iInfected, -1, true, view_as<bool>(respawnOverride), view_as<bool>(respawn));
		CPrintToChat(client, "%t", "Immunity From Infection", iInfected);
	}
}

public int FindNewInfected(int client)
{
	int clients[MAXPLAYERS+1];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i) && i != client && (g_bImmunity[i] == false))
			clients[clientCount++] = i;
			
	return (clientCount == 0) ? 0 : clients[GetRandomInt(0, clientCount-1)];
}

public void ReloadCfgFile()
{
	for(int i=0; i<4;i++)
	{
		ClearArray(Config_Defender_Perk_List[i]);
		ClearArray(Config_Infector_Perk_List[i]);
	}
	KeyValues KvConfig = CreateKeyValues("TopDefenders_Perk");
	char ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/topdefenders.cfg");
	if ( !FileToKeyValues(KvConfig, ConfigFile) )
	{
		CloseHandle(KvConfig);
		LogError("[ERROR] Don't open file to keyvalues: %s", ConfigFile);
		return;
	}
	
	char cNameKey[4][] = {"First", "Second", "Third", "Other"};
	
	KvConfig.Rewind();
	KvConfig.GetColor4("HUD_TopDefenders_Color", Config_HUD_Defender_Color);
	Config_HUD_Defender_x = KvConfig.GetFloat("HUD_TopDefenders_x");
	Config_HUD_Defender_y = KvConfig.GetFloat("HUD_TopDefenders_y");
	KvConfig.GetColor4("HUD_TopInfectors_Color", Config_HUD_Infector_Color);
	Config_HUD_Infector_x = KvConfig.GetFloat("HUD_TopInfectors_x");
	Config_HUD_Infector_y = KvConfig.GetFloat("HUD_TopInfectors_y");
	KvConfig.Rewind();
	if(KvConfig.JumpToKey("TopDefenders"))
	{
		for(int i=0; i<4 ;i++)
		{
			if(KvConfig.JumpToKey(cNameKey[i]))
			{
				if(i<3)
				{
					int Immunity = KvConfig.GetNum("Immunity_First_Infection");
					if(Immunity==1) Config_Defender_Immunity[i]=true;
						else Config_Defender_Immunity[i]=false;
				}
				Config_Defender_Speed[i] = KvConfig.GetFloat("Add_Speed");
				Config_Defender_Gravity[i] = KvConfig.GetFloat("Subtract_Gravity");
				#if defined SHOP
				Config_Defender_Shop[i] = KvConfig.GetNum("Shop_Give_Credits");
				#endif
				char szBuffer[256];
				KvConfig.GetString("Perk", szBuffer, sizeof(szBuffer));
				if(StrEqual(szBuffer,"Sprite",false)) Config_Defender_Perk_Type[i] = 1;
					else if(StrEqual(szBuffer,"Trail",false)) Config_Defender_Perk_Type[i] = 2;
						else if(StrEqual(szBuffer,"Model",false)) Config_Defender_Perk_Type[i] = 3;
							else Config_Defender_Perk_Type[i] = 0;
				if(Config_Defender_Perk_Type[i] != 0)
				{
					KvConfig.GetColor4("Perk_Color", Config_Defender_Perk_Color[i]);
					Config_Defender_RenderMode[i] = KvConfig.GetNum("Perk_RenderMode");
					if(Config_Defender_Perk_Type[i] == 2)
					{
						Config_Defender_Trail_Config[i][0] = KvConfig.GetFloat("Trail_LifeTime");
						Config_Defender_Trail_Config[i][1] = KvConfig.GetFloat("Trail_Width_Start");
						Config_Defender_Trail_Config[i][2] = KvConfig.GetFloat("Trail_Width_End");
					}
					if(KvConfig.JumpToKey("Perk_List"))
					{
						bool sectionExists = KvConfig.GotoFirstSubKey();
						if (sectionExists)
						{
							char filename[PLATFORM_MAX_PATH];
							while (sectionExists)
							{
								KvConfig.GetString("object", filename, sizeof(filename));
								PushArrayString(Config_Defender_Perk_List[i], filename);
								PrecacheModel(filename);
								sectionExists = KvConfig.GotoNextKey();
							}
							KvConfig.GoBack();
						}
						KvConfig.GoBack(); 
					}
				}
				KvConfig.GoBack(); 
			}
		}
	}
	KvConfig.Rewind();
	if(KvConfig.JumpToKey("TopInfectors"))
	{
		for(int i=0; i<4 ;i++)
		{
			if(KvConfig.JumpToKey(cNameKey[i]))
			{
				if(i<3)
				{
					int Immunity = KvConfig.GetNum("Immunity_First_Infection");
					if(Immunity==1) Config_Infector_Immunity[i]=true;
						else Config_Infector_Immunity[i]=false;
				}
				Config_Infector_Speed[i] = KvConfig.GetFloat("Add_Speed");
				Config_Infector_Gravity[i] = KvConfig.GetFloat("Subtract_Gravity");
				#if defined SHOP
				Config_Infector_Shop[i] = KvConfig.GetNum("Shop_Give_Credits");
				#endif
				char szBuffer[256];
				KvConfig.GetString("Perk", szBuffer, sizeof(szBuffer));
				if(StrEqual(szBuffer,"Sprite",false)) Config_Infector_Perk_Type[i] = 1;
					else if(StrEqual(szBuffer,"Trail",false)) Config_Infector_Perk_Type[i] = 2;
						else if(StrEqual(szBuffer,"Model",false)) Config_Infector_Perk_Type[i] = 3;
							else Config_Infector_Perk_Type[i] = 0;
				if(Config_Infector_Perk_Type[i] != 0)
				{
					KvConfig.GetColor4("Perk_Color", Config_Infector_Perk_Color[i]);
					Config_Infector_RenderMode[i] = KvConfig.GetNum("Perk_RenderMode");
					if(Config_Infector_Perk_Type[i] == 2)
					{
						Config_Infector_Trail_Config[i][0] = KvConfig.GetFloat("Trail_LifeTime");
						Config_Infector_Trail_Config[i][1] = KvConfig.GetFloat("Trail_Width_Start");
						Config_Infector_Trail_Config[i][2] = KvConfig.GetFloat("Trail_Width_End");
					}
					if(KvConfig.JumpToKey("Perk_List"))
					{
						bool sectionExists = KvConfig.GotoFirstSubKey();
						if (sectionExists)
						{
							char filename[PLATFORM_MAX_PATH];
							while (sectionExists)
							{
								KvConfig.GetString("object", filename, sizeof(filename));
								PushArrayString(Config_Infector_Perk_List[i], filename);
								PrecacheModel(filename);
								sectionExists = KvConfig.GotoNextKey();
							}
							KvConfig.GoBack();
						}
						KvConfig.GoBack(); 
					}
				}
				KvConfig.GoBack(); 
			}
		}
	}
	
	CloseHandle(KvConfig);
	
	Cfg_Loaded = true;
}

public void AddToDownload()
{
	char ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/topdefenders_downloadlist.ini");
	Handle hFile = OpenFile(ConfigFile, "r");
	if (hFile)
	{
		char filename[PLATFORM_MAX_PATH];
		while (!IsEndOfFile(hFile) && ReadFileLine(hFile, filename, PLATFORM_MAX_PATH))
		{
			if (TrimString(filename) > 2 && IsCharAlpha(filename[0]))
				AddFileToDownloadsTable(filename);
		}
		CloseHandle(hFile);
	}
	else
		LogError("[ERROR] Don't open file: %s", ConfigFile);
}

public Action ConfigRefresh(int client, int args)
{
	ReloadCfgFile();
	CPrintToChatAll("%t", "Config Refresh");
}

public Action ConfigTest_Defenders(int client, int args)
{
	ReloadCfgFile();
	CPrintToChat(client, "{green}[TopDefenders] {default}Config Test");
	CPrintToChat(client, "{orange}HUD Color: {red}%i {green}%i {blue}%i {white}%i {orange}Position: {purple}%.2f|%.2f", Config_HUD_Defender_Color[0], Config_HUD_Defender_Color[1], Config_HUD_Defender_Color[2], Config_HUD_Defender_Color[3], Config_HUD_Defender_x, Config_HUD_Defender_y);
	for(int i=0;i<4;i++)
	{
		CPrintToChat(client, "{orange}Number: {purple}%i",i+1);
		if(i<3) CPrintToChat(client, "{orange}Immunity: {purple}%i", Config_Defender_Immunity[i]);
		CPrintToChat(client, "{orange}Speed: {purple}%.2f {orange}Gravity: {purple}%.2f {orange}Perk Type: {purple}%i", Config_Defender_Speed[i], Config_Defender_Gravity[i], Config_Defender_Perk_Type[i]);
		#if defined SHOP
		CPrintToChat(client, "{orange}Shop Credits: {purple}%i", Config_Defender_Shop[i]);
		#endif
		if(Config_Defender_Perk_Type[i]!=0)
		{
			CPrintToChat(client, "{orange}Perk Color: {red}%i {green}%i {blue}%i {white}%i {orange}Perk RenderMode: {purple}%i",Config_Defender_Perk_Color[i][0],Config_Defender_Perk_Color[i][1],Config_Defender_Perk_Color[i][2],Config_Defender_Perk_Color[i][3], Config_Defender_RenderMode[i]);
			if(Config_Defender_Perk_Type[i]==2)
				CPrintToChat(client, "{orange}Trail Config: {green}LifeTime-{purple}%.2f,{green}Start-{purple}%.2f,{green}End-{purple}%.2f",Config_Defender_Trail_Config[i][0],Config_Defender_Trail_Config[i][1],Config_Defender_Trail_Config[i][2]);
			int Perk_List_Size = GetArraySize(Config_Defender_Perk_List[i]);
			char filename[PLATFORM_MAX_PATH];
			for(int j=0;j<Perk_List_Size;j++)
			{
				GetArrayString(Config_Defender_Perk_List[i], j, filename, sizeof(filename));	
				CPrintToChat(client, "{orange}Object: {purple}%s", filename);
			}
		}
		CPrintToChat(client, "---------------------------------");
	}
}

public Action ConfigTest_Infectors(int client, int args)
{
	ReloadCfgFile();
	CPrintToChat(client, "{red}[TopInfectors] {default}Config Test");
	CPrintToChat(client, "{orange}HUD Color: {red}%i {green}%i {blue}%i {white}%i {orange}Position: {purple}%.2f|%.2f", Config_HUD_Infector_Color[0], Config_HUD_Infector_Color[1], Config_HUD_Infector_Color[2], Config_HUD_Infector_Color[3], Config_HUD_Infector_x, Config_HUD_Infector_y);
	for(int i=0;i<4;i++)
	{
		CPrintToChat(client, "{orange}Number: {purple}%i",i+1);
		if(i<3) CPrintToChat(client, "{orange}Immunity: {purple}%i", Config_Infector_Immunity[i]);
		CPrintToChat(client, "{orange}Speed: {purple}%.2f {orange}Gravity: {purple}%.2f {orange}Perk Type: {purple}%i", Config_Infector_Speed[i], Config_Infector_Gravity[i], Config_Infector_Perk_Type[i]);
		#if defined SHOP
		CPrintToChat(client, "{orange}Shop Credits: {purple}%i", Config_Infector_Shop[i]);
		#endif
		if(Config_Infector_Perk_Type[i]!=0)
		{
			CPrintToChat(client, "{orange}Perk Color: {red}%i {green}%i {blue}%i {white}%i {orange}Perk RenderMode: {purple}%i",Config_Infector_Perk_Color[i][0],Config_Infector_Perk_Color[i][1],Config_Infector_Perk_Color[i][2],Config_Infector_Perk_Color[i][3], Config_Infector_RenderMode[i]);
			if(Config_Infector_Perk_Type[i]==2)
				CPrintToChat(client, "{orange}Trail Config: {green}LifeTime-{purple}%.2f,{green}Start-{purple}%.2f,{green}End-{purple}%.2f",Config_Infector_Trail_Config[i][0],Config_Infector_Trail_Config[i][1],Config_Infector_Trail_Config[i][2]);
			int Perk_List_Size = GetArraySize(Config_Infector_Perk_List[i]);
			char filename[PLATFORM_MAX_PATH];
			for(int j=0;j<Perk_List_Size;j++)
			{
				GetArrayString(Config_Infector_Perk_List[i], j, filename, sizeof(filename));	
				CPrintToChat(client, "{orange}Object: {purple}%s", filename);
			}
		}
		CPrintToChat(client, "---------------------------------");
	}
}

//remove perk on death
public Action Check_Human_Alive(Handle timer)
{
	if(g_bPerk || g_bInfectorPerk)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && IsClientInGame(client) && ((GetClientTeam(client) < 2) || (IsPlayerAlive(client) == false)))
			{
				if(g_iEntityPerk[client] != -1)
				{
					if(IsValidEdict(g_iEntityPerk[client])) AcceptEntityInput(g_iEntityPerk[client], "Kill");//kill perk
					g_iEntityPerk[client]=-1;
				}
			}
		}
	}
	return Plugin_Continue;
}

//command perk remove
public Action PerkRemove(int client, int args)
{
	if(g_bPerk || g_bInfectorPerk)
	{
		if (IsValidClient(client) && IsClientInGame(client))
		{
			if(g_iEntityPerk[client] != -1)
			{
				CPrintToChat(client, "%t", "Perk Remove");
				if(IsValidEdict(g_iEntityPerk[client])) AcceptEntityInput(g_iEntityPerk[client], "Kill");//kill perk
				g_iEntityPerk[client]=-1;
				SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);//speed
				SetEntityGravity(client, 1.0);//gravity
			}else{
				CPrintToChat(client, "%t", "No Perk");
			}
		}
	}
}

stock bool IsValidClient(int client) 
{ 
	if (client > 0 && client <= MaxClients && IsValidEdict(client)) return true; 
	return false; 
}
