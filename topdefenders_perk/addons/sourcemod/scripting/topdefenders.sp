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

//classes
enum struct class_Config
{
	#if defined SHOP
	int				Shop[4];
	#endif
	bool			Immunity[3];
	float			Speed[4];
	float			Gravity[4];
	int				Perk_Type[4]; //0 - None, 1 - Sprite, 2 - Trail, 3 - Model
	int				Perk_Color_Red[4];
	int				Perk_Color_Green[4];
	int				Perk_Color_Blue[4];
	int				Perk_Color_Alpha[4];
	int				RMode[4]; //Rendermode
	float			Trail_LifeTime[4];
	float			Trail_WidthStart[4];
	float			Trail_WidthEnd[4];
	Handle			Perk_List[4];
	
	void InitConfig()
	{
		for(int i=0; i<4;i++) this.Perk_List[i] = CreateArray(PLATFORM_MAX_PATH);
	}
	void ClearData()
	{
		for(int i=0; i<4;i++)
		{
			#if defined SHOP
			this.Shop[i] = 0;
			#endif
			this.Speed[i] = 0.0;
			this.Gravity[i] = 0.0;
			this.Perk_Type[i] = 0;
			this.Perk_Color_Red[i] = 0;
			this.Perk_Color_Green[i] = 0;
			this.Perk_Color_Blue[i] = 0;
			this.Perk_Color_Alpha[i] = 0;
			this.RMode[i] = 0;
			this.Trail_LifeTime[i] = 0.0;
			this.Trail_WidthStart[i] = 0.0;
			this.Trail_WidthEnd[i] = 0.0;
			ClearArray(this.Perk_List[i]);
		}
		this.Immunity[0] = false;
		this.Immunity[1] = false;
		this.Immunity[2] = false;
	}
}

enum struct class_Player
{
	int		Damage;
	int		Kills;
	int		Infects;
	int		TopNextRound;
	int		CurrentDamage;
	int		Perk;
	bool	BlockTimer;
	bool	Immunity;
	
	void Wipe()
	{
		this.Damage			= 0;
		this.Kills			= 0;
		this.Infects		= 0;
		this.TopNextRound	= 0;
		this.CurrentDamage	= 0;
		this.Perk			= -1;
		this.BlockTimer		= false;
		this.Immunity		= false;
	}
	void WipeInGame()
	{
		this.Damage = 0;
		this.Kills = 0;
		this.Infects = 0;
		this.TopNextRound = 0;
	}
}

enum struct class_ConVar
{
	ConVar		cvEnable;
	ConVar		cvTopCount;
	ConVar		cvPerk;
	ConVar		cvTopInfector;
	ConVar		cvInfectorCount;
	ConVar		cvInfectorPerk;
	ConVar		cvShowDamage;
	ConVar		cvCashDiv;
	ConVar		cvImmunity;
	ConVar		cvMinPlayers;
	ConVar		cvMinPlPerk;
	ConVar		cvMaxMoney;
	
	bool		Defender_Enable;
	int			Defender_TopCount;
	bool		Defender_Perk;
	bool		Infector_Enable;
	int			Infector_TopCount;
	bool		Infector_Perk;
	bool		ShowDamage;
	float		CashDiv;
	int			Chance;
	int			MP_Immunity;
	int			MP_Perk;
	int			MaxMoney;
	
	void Init()
	{
		this.Defender_Enable = true;
		this.Defender_TopCount = 3;
		this.Defender_Perk = true;
		this.Infector_Enable = true;
		this.Infector_TopCount = 3;
		this.Infector_Perk = true;
		this.ShowDamage = true;
		this.CashDiv = 20.0;
		this.Chance = 100;
		this.MP_Immunity = 15;
		this.MP_Perk = 10;
		this.MaxMoney = 16000;
	}
}

class_ConVar g_cConVar;

class_Config cDefender;
class_Config cInfector;

class_Player cPlayers[MAXPLAYERS+1];

int		g_iInfectedChance = 0;
int		g_iCash = -1;
bool	g_bCfg_Loaded = false;
bool	g_bWarmUp = false;

public Plugin myinfo = 
{
	name = "[ZR] TopDefenders with Perk CS:GO",
	author = "DarkerZ [RUS]",
	description = "Shows damage by zombies and gives perk for the top",
	version = "2.4.0",
	url = "dark-skill.ru"
}

public void OnPluginStart()
{
	LoadTranslations("topdefenders_perk.phrases");
	
	g_iCash = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (g_iCash == -1) SetFailState("[CS:GO] Give Cash - Failed to find offset for m_iAccount!");
	
	cDefender.InitConfig();
	cInfector.InitConfig();
	
	g_cConVar.Init();
	g_cConVar.cvEnable			= CreateConVar("sm_topdefenders_enable", "1", "[TopDefenders] Enable plugin", _, true, 0.0, true, 1.0);
	g_cConVar.cvTopCount		= CreateConVar("sm_topdefenders_topcount", "3", "[TopDefenders] Count top on round end (min 3/max 15)", _, true, 3.0, true, 15.0);
	g_cConVar.cvPerk			= CreateConVar("sm_topdefenders_perk", "1", "[TopDefenders] Gives perk for the top", _, true, 0.0, true, 1.0);
	g_cConVar.cvTopInfector		= CreateConVar("sm_topdefenders_infectors_enable", "1", "[TopDefenders] Enable Top Infector Addon", _, true, 0.0, true, 1.0);
	g_cConVar.cvInfectorCount	= CreateConVar("sm_topdefenders_infectors_topcount", "3", "[TopDefenders] Count top Infector on round end (min 3/max 15)", _, true, 3.0, true, 15.0);
	g_cConVar.cvInfectorPerk	= CreateConVar("sm_topdefenders_infectors_perk", "1", "[TopDefenders] Gives Infector perk for the top", _, true, 0.0, true, 1.0);
	
	g_cConVar.cvShowDamage		= CreateConVar("sm_topdefenders_showdamage", "1", "[TopDefenders] Enable Show Damage Addon", _, true, 0.0, true, 1.0);
	g_cConVar.cvCashDiv			= CreateConVar("sm_topdefenders_cashdiv", "20", "[TopDefenders] Divider (min 0/max 50; 0 - Disable)", _, true, 0.0, true, 50.0);
	g_cConVar.cvImmunity		= CreateConVar("sm_topdefenders_immunity_chance", "100", "[TopDefenders] Immunity Chance", _, true, 0.0, true, 100.0);
	g_cConVar.cvMinPlayers		= CreateConVar("sm_topdefenders_immunity_minplayers", "15", "[TopDefenders] Minimum players for immunity", _, true, 10.0, true, 64.0);
	g_cConVar.cvMinPlPerk		= CreateConVar("sm_topdefenders_perk_minplayers", "10", "[TopDefenders] Minimum players for give Perk and Credits", _, true, 1.0, true, 64.0);
	g_cConVar.cvMaxMoney		= FindConVar("mp_maxmoney");
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	g_cConVar.Defender_Enable		= g_cConVar.cvEnable.BoolValue;
	g_cConVar.Defender_TopCount		= g_cConVar.cvTopCount.IntValue;
	g_cConVar.Defender_Perk			= g_cConVar.cvPerk.BoolValue;
	g_cConVar.Infector_Enable		= g_cConVar.cvTopInfector.BoolValue;
	g_cConVar.Infector_TopCount		= g_cConVar.cvInfectorCount.IntValue;
	g_cConVar.Infector_Perk			= g_cConVar.cvInfectorPerk.BoolValue;
	g_cConVar.ShowDamage			= g_cConVar.cvShowDamage.BoolValue;
	g_cConVar.CashDiv				= g_cConVar.cvCashDiv.FloatValue;
	g_cConVar.Chance				= g_cConVar.cvImmunity.IntValue;
	g_cConVar.MP_Immunity			= g_cConVar.cvMinPlayers.IntValue;
	g_cConVar.MP_Perk				= g_cConVar.cvMinPlPerk.IntValue;
	g_cConVar.MaxMoney				= g_cConVar.cvMaxMoney.IntValue;
	
	HookConVarChange(g_cConVar.cvEnable,		Cvar_Changed);
	HookConVarChange(g_cConVar.cvTopCount,		Cvar_Changed);
	HookConVarChange(g_cConVar.cvPerk,			Cvar_Changed);
	HookConVarChange(g_cConVar.cvTopInfector,	Cvar_Changed);
	HookConVarChange(g_cConVar.cvInfectorCount,	Cvar_Changed);
	HookConVarChange(g_cConVar.cvInfectorPerk,	Cvar_Changed);
	
	HookConVarChange(g_cConVar.cvShowDamage,	Cvar_Changed);
	HookConVarChange(g_cConVar.cvCashDiv,		Cvar_Changed);
	HookConVarChange(g_cConVar.cvImmunity,		Cvar_Changed);
	HookConVarChange(g_cConVar.cvMinPlayers,	Cvar_Changed);
	HookConVarChange(g_cConVar.cvMinPlPerk,		Cvar_Changed);
	HookConVarChange(g_cConVar.cvMaxMoney,		Cvar_Changed);
		
	RegConsoleCmd("sm_pr", PerkRemove, "[TopDefender] Remove Perk from yourself");
	
	RegAdminCmd("sm_topdefenders_config_test1", ConfigTest_Defenders, ADMFLAG_ROOT, "[TopDefenders] Config Test Defenders");
	RegAdminCmd("sm_topdefenders_config_test2", ConfigTest_Infectors, ADMFLAG_ROOT, "[TopDefenders] Config Test Infectors");
	RegAdminCmd("sm_topdefenders_refresh", ConfigRefresh, ADMFLAG_CONVARS, "[TopDefenders] Refresh Config");
	
	AutoExecConfig(true, "topdefenders_perk");
}

public void Cvar_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==g_cConVar.cvEnable)
		g_cConVar.Defender_Enable = GetConVarBool(convar);
	else if(convar==g_cConVar.cvTopCount)
		g_cConVar.Defender_TopCount = GetConVarInt(convar);	
	else if(convar==g_cConVar.cvPerk)
		g_cConVar.Defender_Perk = GetConVarBool(convar);
	else if(convar==g_cConVar.cvTopInfector)
		g_cConVar.Infector_Enable = GetConVarBool(convar);
	else if(convar==g_cConVar.cvInfectorCount)
		g_cConVar.Infector_TopCount = GetConVarInt(convar);
	else if(convar==g_cConVar.cvInfectorPerk)
		g_cConVar.Infector_Perk = GetConVarBool(convar);		
	else if(convar==g_cConVar.cvShowDamage)
		g_cConVar.ShowDamage = GetConVarBool(convar);	
	else if(convar==g_cConVar.cvCashDiv)
		g_cConVar.CashDiv = GetConVarFloat(convar);	
	else if(convar==g_cConVar.cvImmunity)
		g_cConVar.Chance = GetConVarInt(convar);
	else if(convar==g_cConVar.cvMinPlayers)
		g_cConVar.MP_Immunity = GetConVarInt(convar);
	else if(convar==g_cConVar.cvMinPlPerk)
		g_cConVar.MP_Perk = GetConVarInt(convar);
	else if(convar==g_cConVar.cvMaxMoney)
		g_cConVar.MaxMoney = GetConVarInt(convar);
}

public void OnMapStart()
{
	AddToDownload();
	g_bCfg_Loaded = false;
	ReloadCfgFile();
	CreateTimer(5.0, Check_Human_Alive, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientConnected(int client)
{
	if(g_cConVar.Defender_Enable) cPlayers[client].Wipe();
}

public void OnClientDisconnect(int client)
{
	if(g_cConVar.Defender_Enable) cPlayers[client].Wipe();
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_cConVar.Defender_Enable) return;
	
	if (GameRules_GetProp("m_bWarmupPeriod") == 1) g_bWarmUp = true;
	else if (GameRules_GetProp("m_bWarmupPeriod") == 0) g_bWarmUp = false;
	
	if(g_bWarmUp) return;
	
	g_iInfectedChance = 0;
	
	for (int client = 1; client <= MaxClients; client++) cPlayers[client].Immunity = false;
	int iIngamePlayers = GetIngamePlayers();
	if(g_cConVar.Defender_Perk && iIngamePlayers >= g_cConVar.MP_Perk) GivePerk_TopDefender();
	if(g_cConVar.Infector_Enable && g_cConVar.Infector_Perk && iIngamePlayers >= g_cConVar.MP_Perk) GivePerk_TopInfector();
	
	//wipe clients
	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsValidEdict(client) && IsClientInGame(client)) SetEntProp(client, Prop_Data, "m_iDeaths", 0);
		cPlayers[client].WipeInGame();
	}
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_cConVar.Defender_Enable) return;
	
	if(g_bWarmUp)
	{
		//wipe clients
		for (int client = 1; client <= MaxClients; client++)
		{
			if(IsValidEdict(client) && IsClientInGame(client)) SetEntProp(client, Prop_Data, "m_iDeaths", 0);
			cPlayers[client].WipeInGame();
		}
		return;
	}
	
	int iDefenderIndex[15] = {-1,...};
	int iInfectorIndex[15] = {-1,...};
	
	//copy
	int iSortDamage[MAXPLAYERS + 1];
	for (int i = 1; i <= MaxClients; i++) iSortDamage[i] = cPlayers[i].Damage;
	//sort
	SortIntegers(iSortDamage, MaxClients+1, Sort_Descending);
	int iCount = 0;
	int iSDindex = 0;
	int iIgnoreLast = 0;
	bool bMasNoEnd = true;
	while(iCount < g_cConVar.Defender_TopCount)
	{
		if(iSortDamage[iSDindex]!=0 && bMasNoEnd)
		{
			if(iSortDamage[iSDindex]!=iIgnoreLast)
			{
				iIgnoreLast = iSortDamage[iSDindex];
				for (int i = 1; i <= MaxClients; i++)
				{
					if (cPlayers[i].Damage == iSortDamage[iSDindex])
					{
						iCount++;
						iDefenderIndex[iCount-1] = i;
						cPlayers[i].TopNextRound = iCount;
					}
					if(iCount == g_cConVar.Defender_TopCount) break;
				}
			}
			if(iSDindex<MaxClients) iSDindex++;
			else bMasNoEnd = false;
		}else iCount++;
	}
	
	if(g_cConVar.Infector_Enable)
	{
		//copy
		for (int i = 1; i <= MaxClients; i++) iSortDamage[i] = cPlayers[i].Infects;
		//sort
		SortIntegers(iSortDamage, MaxClients+1, Sort_Descending);
		iCount = 0;
		iSDindex = 0;
		iIgnoreLast = 0;
		bMasNoEnd = true;
		while(iCount < g_cConVar.Infector_TopCount)
		{
			if(iSortDamage[iSDindex]!=0 && bMasNoEnd)
			{
				if(iSortDamage[iSDindex]!=iIgnoreLast)
				{
					iIgnoreLast = iSortDamage[iSDindex];
					for (int i = 1; i <= MaxClients; i++)
					{
						if (cPlayers[i].Infects == iSortDamage[iSDindex])
						{
							iCount++;
							iInfectorIndex[iCount-1] = i;
							cPlayers[i].TopNextRound = -iCount;
						}
						if(iCount == g_cConVar.Infector_TopCount) break;
					}
				}
				if(iSDindex<MaxClients) iSDindex++;
				else bMasNoEnd = false;
			}else iCount++;
		}
	}
	
	//show
	CPrintToChatAll("%t", "Chat Top Defenders");
	for(int j = 0; j < g_cConVar.Defender_TopCount; j++)
	{
		if(iDefenderIndex[j] != -1)
		{
			if(j==0) CPrintToChatAll("%t", "Chat Top DefFirst", j+1, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
			else if(j==1) CPrintToChatAll("%t", "Chat Top DefSecond", j+1, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
			else if(j==2) CPrintToChatAll("%t", "Chat Top DefThird", j+1, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
			else CPrintToChatAll("%t", "Chat Top DefOther", j+1, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
		}else CPrintToChatAll("%t", "Chat Top DefNone", j+1);
	}
	if(g_cConVar.Infector_Enable)
	{
		CPrintToChatAll("%t", "Chat Top Infectors");
		for(int j = 0; j < g_cConVar.Infector_TopCount; j++)
		{
			if(iInfectorIndex[j] != -1)
			{
				if(j==0) CPrintToChatAll("%t", "Chat Top InfFirst",j+1, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
				else if(j==1) CPrintToChatAll("%t", "Chat Top InfSecond",j+1, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
				else if(j==2) CPrintToChatAll("%t", "Chat Top InfThird",j+1, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
				else CPrintToChatAll("%t", "Chat Top InfOther",j+1, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
			}else CPrintToChatAll("%t", "Chat Top InfNone", j+1);
		}
	}
	//hud
	for(int z = 1; z <= MaxClients; z++)
		if(IsClientInGame(z) && !IsFakeClient(z))
		{
			char sHUD[16384];
			FormatEx(sHUD, sizeof(sHUD), "%T<br>", "HUD Top Defenders", z);
			for(int j = 0; j < g_cConVar.Defender_TopCount; j++)
			{
				if(iDefenderIndex[j] != -1)
				{
					if(j==0) Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top DefPosition First", z, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
					else if(j==1) Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top DefPosition Second", z, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
					else if(j==2) Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top DefPosition Third", z, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
					else Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top DefPosition Other", z, j+1, iDefenderIndex[j], cPlayers[iDefenderIndex[j]].Damage);
				}else Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top DefNone", z, j+1);
			}
			if(g_cConVar.Infector_Enable)
			{
				Format(sHUD, sizeof(sHUD), "%s<br>%T<br>", sHUD, "HUD Top Infectors", z);
				for(int j = 0; j < g_cConVar.Infector_TopCount; j++)
				{
					if(iInfectorIndex[j] != -1)
					{
						if(j==0) Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top InfPosition First", z, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
						else if(j==1) Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top InfPosition Second", z, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
						else if(j==2) Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top InfPosition Third", z, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
						else Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top InfPosition Other", z, j+1, iInfectorIndex[j], cPlayers[iInfectorIndex[j]].Infects);
					}else Format(sHUD, sizeof(sHUD), "%s%T<br>", sHUD, "HUD Top InfNone", z, j+1);
				}
			}	
			Event newEMessage = CreateEvent("cs_win_panel_round");
			newEMessage.SetString("funfact_token", sHUD);
			newEMessage.FireToClient(z);
			newEMessage.Cancel();
		}
	#if defined SHOP
	//Give Credits
	if(GetIngamePlayers() >= g_cConVar.MP_Perk)
	{
		for(int j = 0; j < g_cConVar.Defender_TopCount; j++)
		{
			if(iDefenderIndex[j] != -1 && IsValidClient(iDefenderIndex[j]) && IsClientInGame(iDefenderIndex[j]) && !IsFakeClient(iDefenderIndex[j]))
			{
				int iPlace = j;
				if(iPlace>3) iPlace=3;
				if(cDefender.Shop[iPlace] > 0)
				{
					CPrintToChat(iDefenderIndex[j], "%t", "Chat Give Credits Defenders", cDefender.Shop[iPlace], j+1);
					SHOP_SET_CREDITS_FUNC(iDefenderIndex[j], SHOP_GET_CREDITS_FUNC(iDefenderIndex[j])+cDefender.Shop[iPlace]);
				}
			}
		}
		if(g_cConVar.Infector_Enable)
		{
			for(int j = 0; j < g_cConVar.Infector_TopCount; j++)
			{
				if(iInfectorIndex[j] != -1 && IsValidClient(iInfectorIndex[j]) && IsClientInGame(iInfectorIndex[j]) && !IsFakeClient(iInfectorIndex[j]))
				{
					int iPlace = j;
					if(iPlace>3) iPlace=3;
					if(cInfector.Shop[iPlace] > 0)
					{
						CPrintToChat(iInfectorIndex[j], "%t", "Chat Give Credits Infectors", cInfector.Shop[iPlace], j+1);
						SHOP_SET_CREDITS_FUNC(iInfectorIndex[j], SHOP_GET_CREDITS_FUNC(iInfectorIndex[j])+cInfector.Shop[iPlace]);
					}
				}
			}
		}
	}
	#endif
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	cPlayers[client].BlockTimer = false;
	if(IsValidClient(client) && IsClientInGame(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T) SetEntProp(client, Prop_Data, "m_iDeaths", cPlayers[client].Infects);
		else if (GetClientTeam(client) == CS_TEAM_CT) SetEntProp(client, Prop_Data, "m_iDeaths", cPlayers[client].Damage/1000);
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_cConVar.Defender_Enable||!g_cConVar.ShowDamage) return;
	int client  = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker) && IsClientInGame(attacker) && IsValidClient(client) && IsClientInGame(client) && !IsFakeClient(attacker) && (attacker != client) && GetClientTeam(attacker) == CS_TEAM_CT && GetClientTeam(client) == CS_TEAM_T)
		cPlayers[attacker].Kills+=1;
}

public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!g_cConVar.Defender_Enable) return;
	int client  = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(IsValidClient(attacker) && IsValidClient(client) && IsClientInGame(attacker) && !IsFakeClient(attacker) && (attacker != client) && GetClientTeam(attacker) == CS_TEAM_CT)
	{
		int iDmg = GetEventInt(event, "dmg_health");
		cPlayers[attacker].Damage += iDmg;
		SetEntProp(attacker, Prop_Data, "m_iDeaths", cPlayers[attacker].Damage/1000);
		if(g_cConVar.ShowDamage) CalcDamage(attacker, iDmg);
		if(g_cConVar.CashDiv > 0.0)
		{
			int iAddCash = GetEntData(attacker, g_iCash) + RoundFloat(iDmg / g_cConVar.CashDiv);
			if(iAddCash > g_cConVar.MaxMoney) iAddCash = g_cConVar.MaxMoney;
			SetEntData(attacker, g_iCash, iAddCash);
		}
	}
}

void CalcDamage(int attacker, int iDmg)
{
	cPlayers[attacker].CurrentDamage += iDmg;
	
	if (cPlayers[attacker].BlockTimer) return;
	
	CreateTimer(0.01, ShowDamageHuman, attacker);
	cPlayers[attacker].BlockTimer = true;
}

public Action ShowDamageHuman(Handle timer, any client)
{
	cPlayers[client].BlockTimer = false;
	if(IsValidClient(client) && IsClientInGame(client))
	{
		PrintHintText(client, "%t", "Hint Damage", cPlayers[client].CurrentDamage, cPlayers[client].Kills, cPlayers[client].Damage);
		cPlayers[client].CurrentDamage = 0;
	}
}

public void GivePerk_TopDefender()
{
	if(g_bCfg_Loaded)
		for(int i = 1; i <= g_cConVar.Defender_TopCount; i++)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if(cPlayers[client].TopNextRound == i)
				{
					if(IsValidEdict(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)))
					{
						//code perk
						int iPlace=i-1;
						if(iPlace>3) iPlace = 3;
						//immunity
						if(iPlace < 3 && cDefender.Immunity[iPlace] == true) cPlayers[client].Immunity = true;
						//speed
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")+cDefender.Speed[iPlace]);
						//gravity
						SetEntityGravity(client, GetEntityGravity(client)-cDefender.Gravity[iPlace]);
						if(cDefender.Perk_Type[iPlace] == 1) SpriteSet(client, iPlace, true);
							else if(cDefender.Perk_Type[iPlace] == 2) TrailSet(client, iPlace, true);
								else if(cDefender.Perk_Type[iPlace] == 3) ModelSet(client, iPlace, true);
					}
					cPlayers[client].TopNextRound = 0;
					break;
				}
			}
		}
}

public void GivePerk_TopInfector()
{
	if(g_bCfg_Loaded)
		for(int i = 1; i <= g_cConVar.Infector_TopCount; i++)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if(cPlayers[client].TopNextRound == -i)
				{
					if(IsValidEdict(client) && IsClientInGame(client) && ((GetClientTeam(client) == CS_TEAM_T) || (GetClientTeam(client) == CS_TEAM_CT)))
					{
						//code perk
						int iPlace=i-1;
						if(iPlace>3) iPlace = 3;
						//immunity
						if(iPlace < 3 && cInfector.Immunity[iPlace] == true) cPlayers[client].Immunity = true;
						//speed
						SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue")+cInfector.Speed[iPlace]);
						//gravity
						SetEntityGravity(client, GetEntityGravity(client)-cInfector.Gravity[iPlace]);
						if(cInfector.Perk_Type[iPlace] == 1) SpriteSet(client, iPlace, false);
							else if(cInfector.Perk_Type[iPlace] == 2) TrailSet(client, iPlace, false);
								else if(cInfector.Perk_Type[iPlace] == 3) ModelSet(client, iPlace, false);
					}
					cPlayers[client].TopNextRound = 0;
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
			int iSize = GetArraySize(cDefender.Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(cDefender.Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(cDefender.RMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", cDefender.Perk_Color_Red[iPlace], cDefender.Perk_Color_Green[iPlace], cDefender.Perk_Color_Blue[iPlace]);
			IntToString(cDefender.Perk_Color_Alpha[iPlace], cAlpha, 4);
		}else
		{
			int iSize = GetArraySize(cInfector.Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(cInfector.Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(cInfector.RMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", cInfector.Perk_Color_Red[iPlace], cInfector.Perk_Color_Green[iPlace], cInfector.Perk_Color_Blue[iPlace]);
			IntToString(cInfector.Perk_Color_Alpha[iPlace], cAlpha, 4);
		}
		float Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 95.0;
		int iEntity = CreateEntityByName("env_sprite");
		if (iEntity < 1)
		{
			LogError("env_sprite create error!");
			return;
		}
		DispatchKeyValueVector(iEntity, "origin", Pos);
		
		DispatchKeyValue(iEntity, "model", filename);
		DispatchKeyValue(iEntity, "rendermode", cRenderMode);
		DispatchKeyValue(iEntity, "rendercolor", cColor);
		DispatchKeyValue(iEntity, "renderamt", cAlpha);
		DispatchKeyValue(iEntity, "spawnflags", "1");
		DispatchKeyValue(iEntity, "scale", "0.1");
		DispatchSpawn(iEntity);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		cPlayers[client].Perk = EntIndexToEntRef(iEntity);
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
			int iSize = GetArraySize(cDefender.Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(cDefender.Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(cDefender.RMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", cDefender.Perk_Color_Red[iPlace], cDefender.Perk_Color_Green[iPlace], cDefender.Perk_Color_Blue[iPlace]);
			IntToString(cDefender.Perk_Color_Alpha[iPlace], cAlpha, 4);
			fLifeTime = cDefender.Trail_LifeTime[iPlace];
			fWidthStart = cDefender.Trail_WidthStart[iPlace];
			fWidthEnd = cDefender.Trail_WidthEnd[iPlace];
		}else
		{
			int iSize = GetArraySize(cInfector.Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(cInfector.Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(cInfector.RMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", cInfector.Perk_Color_Red[iPlace], cInfector.Perk_Color_Green[iPlace], cInfector.Perk_Color_Blue[iPlace]);
			IntToString(cInfector.Perk_Color_Alpha[iPlace], cAlpha, 4);
			fLifeTime = cInfector.Trail_LifeTime[iPlace];
			fWidthStart = cInfector.Trail_WidthStart[iPlace];
			fWidthEnd = cInfector.Trail_WidthEnd[iPlace];
		}
		float Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 10.0;
		int iEntity = CreateEntityByName("env_spritetrail");
		if (iEntity < 1)
		{
			LogError("env_spritetrail create error!");
			return;
		}
		SetEntPropFloat(iEntity, Prop_Send, "m_flTextureRes", 0.05);
		DispatchKeyValueVector(iEntity, "origin", Pos);
		
		DispatchKeyValue(iEntity, "spritename", filename);
		DispatchKeyValue(iEntity, "rendermode", cRenderMode);
		DispatchKeyValue(iEntity, "rendercolor", cColor);
		DispatchKeyValue(iEntity, "renderamt", cAlpha);
		DispatchKeyValueFloat(iEntity, "lifetime", fLifeTime);
		DispatchKeyValueFloat(iEntity, "startwidth", fWidthStart);
		DispatchKeyValueFloat(iEntity, "endwidth", fWidthEnd);
		DispatchSpawn(iEntity);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		AcceptEntityInput(iEntity, "ShowSprite");
		//fix spritetrail CS GO
		SetVariantString("OnUser1 !self:SetScale:1:0.5:-1");
		AcceptEntityInput(iEntity, "AddOutput");
		AcceptEntityInput(iEntity, "FireUser1");
		cPlayers[client].Perk = EntIndexToEntRef(iEntity);
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
			int iSize = GetArraySize(cDefender.Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(cDefender.Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(cDefender.RMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", cDefender.Perk_Color_Red[iPlace], cDefender.Perk_Color_Green[iPlace], cDefender.Perk_Color_Blue[iPlace]);
		}else
		{
			int iSize = GetArraySize(cInfector.Perk_List[iPlace]);
			if (!iSize) return;

			GetArrayString(cInfector.Perk_List[iPlace], GetRandomInt(0, iSize-1),filename,sizeof(filename));	
			IntToString(cInfector.RMode[iPlace], cRenderMode, 3);
			FormatEx(cColor, sizeof(cColor), "%i %i %i", cInfector.Perk_Color_Red[iPlace], cInfector.Perk_Color_Green[iPlace], cInfector.Perk_Color_Blue[iPlace]);
		}
		float Pos[3];
		GetClientAbsOrigin(client, Pos);
		Pos[2] += 85.0;
		int iEntity = CreateEntityByName("prop_dynamic");
		if (iEntity < 1)
		{
			LogError("prop_dynamic create error!");
			return;
		}
		DispatchKeyValueVector(iEntity, "origin", Pos);
		
		DispatchKeyValue(iEntity, "spawnflags", "256");
		DispatchKeyValue(iEntity, "solid", "0");
		DispatchKeyValue(iEntity, "DisableShadows", "1");
		DispatchKeyValue(iEntity, "model", filename);
		DispatchKeyValue(iEntity, "rendermode", cRenderMode);
		DispatchKeyValue(iEntity, "rendercolor", cColor);
		DispatchKeyValue(iEntity, "renderamt", "254");
		DispatchSpawn(iEntity);
		
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", client);
		AcceptEntityInput(iEntity, "TurnOn", iEntity, iEntity, 0);
		cPlayers[client].Perk = EntIndexToEntRef(iEntity);
	}
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if(!g_cConVar.Defender_Enable) return Plugin_Continue;
	if(motherInfect && cPlayers[client].Immunity && GetRandomInt(0, 100) <= g_cConVar.Chance)
	{
		if(GetIngamePlayers()<g_cConVar.MP_Immunity ) return Plugin_Continue;
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
	if(!g_cConVar.Defender_Enable) return;
	if(!motherInfect && IsValidClient(attacker) && IsValidClient(client) && !IsFakeClient(attacker) && IsClientInGame(attacker) && (attacker != client))
	{
		cPlayers[attacker].Infects += 1;
		SetEntProp(attacker, Prop_Data, "m_iDeaths", cPlayers[attacker].Infects);
		if(g_cConVar.ShowDamage) PrintHintText(attacker, "%t", "Hint Infect", client, cPlayers[attacker].Infects);
		if(IsClientInGame(client)) SetEntProp(client, Prop_Data, "m_iDeaths", cPlayers[client].Infects); 
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
		if (IsClientInGame(i) && IsPlayerAlive(i) && ZR_IsClientHuman(i) && i != client && (cPlayers[i].Immunity == false))
			clients[clientCount++] = i;
			
	return (clientCount == 0) ? 0 : clients[GetRandomInt(0, clientCount-1)];
}

public void ReloadCfgFile()
{
	cDefender.ClearData();
	cInfector.ClearData();
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
	if(KvConfig.JumpToKey("TopDefenders"))
	{
		for(int i=0; i<4 ;i++)
		{
			if(KvConfig.JumpToKey(cNameKey[i]))
			{
				if(i<3)
				{
					int Immunity = KvConfig.GetNum("Immunity_First_Infection");
					if(Immunity==1) cDefender.Immunity[i]=true;
						else cDefender.Immunity[i]=false;
				}
				cDefender.Speed[i] = KvConfig.GetFloat("Add_Speed");
				cDefender.Gravity[i] = KvConfig.GetFloat("Subtract_Gravity");
				#if defined SHOP
				cDefender.Shop[i] = KvConfig.GetNum("Shop_Give_Credits");
				#endif
				char szBuffer[256];
				KvConfig.GetString("Perk", szBuffer, sizeof(szBuffer));
				if(StrEqual(szBuffer,"Sprite",false)) cDefender.Perk_Type[i] = 1;
					else if(StrEqual(szBuffer,"Trail",false)) cDefender.Perk_Type[i] = 2;
						else if(StrEqual(szBuffer,"Model",false)) cDefender.Perk_Type[i] = 3;
							else cDefender.Perk_Type[i] = 0;
				if(cDefender.Perk_Type[i] != 0)
				{
					int iNewColor[4];
					KvConfig.GetColor4("Perk_Color", iNewColor);
					cDefender.Perk_Color_Red[i] = iNewColor[0];
					cDefender.Perk_Color_Green[i] = iNewColor[1];
					cDefender.Perk_Color_Blue[i] = iNewColor[2];
					cDefender.Perk_Color_Alpha[i] = iNewColor[3];
					cDefender.RMode[i] = KvConfig.GetNum("Perk_RenderMode");
					if(cDefender.Perk_Type[i] == 2)
					{
						cDefender.Trail_LifeTime[i] = KvConfig.GetFloat("Trail_LifeTime");
						cDefender.Trail_WidthStart[i] = KvConfig.GetFloat("Trail_Width_Start");
						cDefender.Trail_WidthEnd[i] = KvConfig.GetFloat("Trail_Width_End");
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
								PushArrayString(cDefender.Perk_List[i], filename);
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
					if(Immunity==1) cInfector.Immunity[i]=true;
						else cInfector.Immunity[i]=false;
				}
				cInfector.Speed[i] = KvConfig.GetFloat("Add_Speed");
				cInfector.Gravity[i] = KvConfig.GetFloat("Subtract_Gravity");
				#if defined SHOP
				cInfector.Shop[i] = KvConfig.GetNum("Shop_Give_Credits");
				#endif
				char szBuffer[256];
				KvConfig.GetString("Perk", szBuffer, sizeof(szBuffer));
				if(StrEqual(szBuffer,"Sprite",false)) cInfector.Perk_Type[i] = 1;
					else if(StrEqual(szBuffer,"Trail",false)) cInfector.Perk_Type[i] = 2;
						else if(StrEqual(szBuffer,"Model",false)) cInfector.Perk_Type[i] = 3;
							else cInfector.Perk_Type[i] = 0;
				if(cInfector.Perk_Type[i] != 0)
				{
					int iNewInfColor[4];
					KvConfig.GetColor4("Perk_Color", iNewInfColor);
					cInfector.Perk_Color_Red[i] = iNewInfColor[0];
					cInfector.Perk_Color_Green[i] = iNewInfColor[1];
					cInfector.Perk_Color_Blue[i] = iNewInfColor[2];
					cInfector.Perk_Color_Alpha[i] = iNewInfColor[3];
					cInfector.RMode[i] = KvConfig.GetNum("Perk_RenderMode");
					if(cInfector.Perk_Type[i] == 2)
					{
						cInfector.Trail_LifeTime[i] = KvConfig.GetFloat("Trail_LifeTime");
						cInfector.Trail_WidthStart[i] = KvConfig.GetFloat("Trail_Width_Start");
						cInfector.Trail_WidthEnd[i] = KvConfig.GetFloat("Trail_Width_End");
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
								PushArrayString(cInfector.Perk_List[i], filename);
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
	
	g_bCfg_Loaded = true;
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
	if (IsValidClient(client) && IsClientInGame(client) && IsClientConnected(client))
	{
		CPrintToChat(client, "{green}[TopDefenders] {default}Config Test");
		for(int i=0;i<4;i++)
		{
			CPrintToChat(client, "{orange}Number: {purple}%i",i+1);
			if(i<3) CPrintToChat(client, "{orange}Immunity: {purple}%i", cDefender.Immunity[i]);
			CPrintToChat(client, "{orange}Speed: {purple}%.2f {orange}Gravity: {purple}%.2f {orange}Perk Type: {purple}%i", cDefender.Speed[i], cDefender.Gravity[i], cDefender.Perk_Type[i]);
			#if defined SHOP
			CPrintToChat(client, "{orange}Shop Credits: {purple}%i", cDefender.Shop[i]);
			#endif
			if(cDefender.Perk_Type[i]!=0)
			{
				CPrintToChat(client, "{orange}Perk Color: {red}%i {green}%i {blue}%i {white}%i {orange}Perk RenderMode: {purple}%i",cDefender.Perk_Color_Red[i],cDefender.Perk_Color_Green[i],cDefender.Perk_Color_Blue[i],cDefender.Perk_Color_Alpha[i], cDefender.RMode[i]);
				if(cDefender.Perk_Type[i]==2)
					CPrintToChat(client, "{orange}Trail Config: {green}LifeTime-{purple}%.2f,{green}Start-{purple}%.2f,{green}End-{purple}%.2f",cDefender.Trail_LifeTime[i],cDefender.Trail_WidthStart[i],cDefender.Trail_WidthEnd[i]);
				int Perk_List_Size = GetArraySize(cDefender.Perk_List[i]);
				char filename[PLATFORM_MAX_PATH];
				for(int j=0;j<Perk_List_Size;j++)
				{
					GetArrayString(cDefender.Perk_List[i], j, filename, sizeof(filename));	
					CPrintToChat(client, "{orange}Object: {purple}%s", filename);
				}
			}
			CPrintToChat(client, "---------------------------------");
		}
	}
}

public Action ConfigTest_Infectors(int client, int args)
{
	ReloadCfgFile();
	if (IsValidClient(client) && IsClientInGame(client) && IsClientConnected(client))
	{
		CPrintToChat(client, "{red}[TopInfectors] {default}Config Test");
		for(int i=0;i<4;i++)
		{
			CPrintToChat(client, "{orange}Number: {purple}%i",i+1);
			if(i<3) CPrintToChat(client, "{orange}Immunity: {purple}%i", cInfector.Immunity[i]);
			CPrintToChat(client, "{orange}Speed: {purple}%.2f {orange}Gravity: {purple}%.2f {orange}Perk Type: {purple}%i", cInfector.Speed[i], cInfector.Gravity[i], cInfector.Perk_Type[i]);
			#if defined SHOP
			CPrintToChat(client, "{orange}Shop Credits: {purple}%i", cInfector.Shop[i]);
			#endif
			if(cInfector.Perk_Type[i]!=0)
			{
				CPrintToChat(client, "{orange}Perk Color: {red}%i {green}%i {blue}%i {white}%i {orange}Perk RenderMode: {purple}%i",cInfector.Perk_Color_Red[i],cInfector.Perk_Color_Green[i],cInfector.Perk_Color_Blue[i],cInfector.Perk_Color_Alpha[i], cInfector.RMode[i]);
				if(cInfector.Perk_Type[i]==2)
					CPrintToChat(client, "{orange}Trail Config: {green}LifeTime-{purple}%.2f,{green}Start-{purple}%.2f,{green}End-{purple}%.2f",cInfector.Trail_LifeTime[i],cInfector.Trail_WidthStart[i],cInfector.Trail_WidthEnd[i]);
				int Perk_List_Size = GetArraySize(cInfector.Perk_List[i]);
				char filename[PLATFORM_MAX_PATH];
				for(int j=0;j<Perk_List_Size;j++)
				{
					GetArrayString(cInfector.Perk_List[i], j, filename, sizeof(filename));	
					CPrintToChat(client, "{orange}Object: {purple}%s", filename);
				}
			}
			CPrintToChat(client, "---------------------------------");
		}
	}
}

//remove perk on death
public Action Check_Human_Alive(Handle timer)
{
	if(g_cConVar.Defender_Perk || g_cConVar.Infector_Perk)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsValidClient(client) && IsClientInGame(client) && ((GetClientTeam(client) < 2) || (IsPlayerAlive(client) == false)))
			{
				int iIndex = EntRefToEntIndex(cPlayers[client].Perk);
				if(iIndex != INVALID_ENT_REFERENCE)
				{
					AcceptEntityInput(iIndex, "Kill");//kill perk
					cPlayers[client].Perk = -1;
				}
			}
		}
	}
	return Plugin_Continue;
}

//command perk remove
public Action PerkRemove(int client, int args)
{
	if(g_cConVar.Defender_Perk || g_cConVar.Infector_Perk)
	{
		if (IsValidClient(client) && IsClientInGame(client) && IsClientConnected(client))
		{
			int iIndex = EntRefToEntIndex(cPlayers[client].Perk);
			if(iIndex != INVALID_ENT_REFERENCE)
			{
				CPrintToChat(client, "%t", "Perk Remove");
				AcceptEntityInput(iIndex, "Kill");//kill perk
				cPlayers[client].Perk = -1;
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