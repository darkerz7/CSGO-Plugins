#define EW_MODULE_HIGHLIGHT

#define RBG_STEP 10
//To change distance use CVAR: sv_highlight_distance. Default 500

#include <highlight>

ConVar	g_hCvar_HighLight_Weapon_Type, 	//0 - Disable, 1 - All, 2 - Team, 3 - Privilege All, 4 - Privilege Team, 5 - Admin and Privilege All, 6 - Admin and Privilege Team
		g_hCvar_HighLight_Weapon_Color, //false - item's color, true - RGB
		g_hCvar_HighLight_Player_Type,	//0 - Disable, 1 - All, 2 - Team, 3 - Privilege All, 4 - Privilege Team, 5 - Admin and Privilege All, 6 - Admin and Privilege Team
		g_hCvar_HighLight_Player_Color;	//false - item's color, true - RGB

int		g_iHL_wtype = 1,
		g_iHL_ptype = 0;

bool	g_iHL_wcolor = false,
		g_iHL_pcolor = false;

bool	g_bMapRunningHL = false;

int		g_iHL_RGB[3] = {200,0,0};

bool	g_bHL_Privilege_Weapon[MAXPLAYERS+1] = {false,...};
bool	g_bHL_Privilege_Player[MAXPLAYERS+1] = {false,...};

stock void EWM_HLight_OnPluginStart()
{
	g_hCvar_HighLight_Weapon_Type   = CreateConVar("entwatch_hl_wtype", "1", "Type of HighLighting of items.", _, true, 0.0, true, 6.0);
	g_hCvar_HighLight_Weapon_Color   = CreateConVar("entwatch_hl_wcolor", "0", "Color of HighLighting of items.", _, true, 0.0, true, 1.0);
	g_hCvar_HighLight_Player_Type   = CreateConVar("entwatch_hl_ptype", "0", "Type of HighLighting of players that own the item.", _, true, 0.0, true, 6.0);
	g_hCvar_HighLight_Player_Color   = CreateConVar("entwatch_hl_pcolor", "0", "Color of HighLighting of players that own the item.", _, true, 0.0, true, 1.0);

	g_iHL_wtype = GetConVarInt(g_hCvar_HighLight_Weapon_Type);
	g_iHL_wcolor = GetConVarBool(g_hCvar_HighLight_Weapon_Color);
	g_iHL_ptype = GetConVarInt(g_hCvar_HighLight_Player_Type);
	g_iHL_pcolor = GetConVarBool(g_hCvar_HighLight_Player_Color);
	
	HookConVarChange(g_hCvar_HighLight_Weapon_Type, Cvar_HIGHLIGHT_Changed);
	HookConVarChange(g_hCvar_HighLight_Weapon_Color, Cvar_HIGHLIGHT_Changed);
	HookConVarChange(g_hCvar_HighLight_Player_Type, Cvar_HIGHLIGHT_Changed);
	HookConVarChange(g_hCvar_HighLight_Player_Color, Cvar_HIGHLIGHT_Changed);
	
	CreateTimer(1.0, EWM_HLight_Timer, _, TIMER_REPEAT);
}

stock void EWM_HLight_OnMapStart()
{
	g_bMapRunningHL = true;
}

stock void EWM_HLight_OnMapEnd()
{
	g_bMapRunningHL = false;
}

stock void EWM_HLight_RoundStart()
{
	for(int i = 0; i < MaxClients; i++) EWM_HLight_OnClientPrivilegeReset(i);
	#if defined EW_MODULE_FORWARDS
	Call_StartForward(g_hOnHLPrivWeaponForward);
	Call_Finish();
	Call_StartForward(g_hOnHLPrivPlayerForward);
	Call_Finish();
	#endif
}

stock void EWM_HLight_OnClientPrivilegeReset(int iClient)
{
	g_bHL_Privilege_Weapon[iClient] = false;
	g_bHL_Privilege_Player[iClient] = false;
}

public void Cvar_HIGHLIGHT_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==g_hCvar_HighLight_Weapon_Type)
		g_iHL_wtype = GetConVarInt(convar);
	else if(convar==g_hCvar_HighLight_Weapon_Color)
		g_iHL_wcolor = GetConVarBool(convar);
	else if(convar==g_hCvar_HighLight_Player_Type)
		g_iHL_ptype = GetConVarInt(convar);
	else if(convar==g_hCvar_HighLight_Player_Color)
		g_iHL_pcolor = GetConVarBool(convar);
}

public Action EWM_HLight_Timer(Handle timer, int client)
{
	if (g_bMapRunningHL && g_bConfigLoaded && (g_iHL_wtype > 0 || g_iHL_ptype > 0))
	{
		for(int i = 0; i<g_ItemList.Length; i++)
		{
			class_ItemList ItemTest;
			g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
			EWM_HLight_Set(ItemTest);
		}
	}
	return Plugin_Continue;
}

stock void EWM_HLight_Set(class_ItemList ItemTest)
{
	if(IsValidEdict(ItemTest.WeaponID))
	{
		if(g_iHL_wcolor || g_iHL_pcolor) EWM_HLight_UpdateRGB();
		if(ItemTest.OwnerID == INVALID_ENT_REFERENCE)
		{ //Weapon HighLight
			if (g_iHL_wtype > 0)
			{
				if(!g_iHL_wcolor) Highlight_Color(ItemTest.WeaponID, ItemTest.GlowColor[0], ItemTest.GlowColor[1], ItemTest.GlowColor[2]);
				else Highlight_Color(ItemTest.WeaponID, g_iHL_RGB[0], g_iHL_RGB[1], g_iHL_RGB[2]);
				switch(g_iHL_wtype)
				{
					case 1: Highlight_SetAll(ItemTest.WeaponID); //All
					case 2: //Team
					{
						if(ItemTest.Team > 1)
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && GetClientTeam(j) == ItemTest.Team) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
						}else Highlight_SetAll(ItemTest.WeaponID);
					}
					case 3: //3 - Privilege All
					{
						int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
						for(int j = 1; j<= MaxClients; j++)
							if(IsValidClient(j) && IsClientConnected(j) && g_bHL_Privilege_Weapon[j]) iPlayers[iNum++] = j;
						Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
					}
					case 4: //4 - Privilege Team
					{
						if(ItemTest.Team > 1)
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && g_bHL_Privilege_Weapon[j] && GetClientTeam(j) == ItemTest.Team) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
						}else
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && g_bHL_Privilege_Weapon[j]) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
						}
					}
					case 5: //5 - Admin and Privilege All
					{
						int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
						for(int j = 1; j<= MaxClients; j++)
							if(IsValidClient(j) && IsClientConnected(j) && (g_bHL_Privilege_Weapon[j] || g_bIsAdmin[j])) iPlayers[iNum++] = j;
						Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
					}
					case 6: //6 - Admin and Privilege Team
					{
						if(ItemTest.Team > 1)
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && (g_bHL_Privilege_Weapon[j] || g_bIsAdmin[j]) && GetClientTeam(j) == ItemTest.Team) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
						}else
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && (g_bHL_Privilege_Weapon[j] || g_bIsAdmin[j])) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.WeaponID, iPlayers, iNum);
						}
					}
				}
			}
		}else
		{ //Players HighLight
			if(g_iHL_ptype > 0 && IsValidClient(ItemTest.OwnerID) && IsClientConnected(ItemTest.OwnerID) && GetClientTeam(ItemTest.OwnerID) > 1)
			{
				if(!g_iHL_pcolor) Highlight_Color(ItemTest.OwnerID, ItemTest.GlowColor[0], ItemTest.GlowColor[1], ItemTest.GlowColor[2]);
				else Highlight_Color(ItemTest.OwnerID, g_iHL_RGB[0], g_iHL_RGB[1], g_iHL_RGB[2]);
				switch(g_iHL_ptype)
				{
					case 1: Highlight_SetAll(ItemTest.OwnerID); //All
					case 2: //Team
					{
						if(ItemTest.Team > 1)
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && GetClientTeam(j) == ItemTest.Team) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
						}else Highlight_SetAll(ItemTest.OwnerID);
					}
					case 3: //3 - Privilege All
					{
						int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
						for(int j = 1; j<= MaxClients; j++)
							if(IsValidClient(j) && IsClientConnected(j) && g_bHL_Privilege_Player[j]) iPlayers[iNum++] = j;
						Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
					}
					case 4: //4 - Privilege Team
					{
						if(ItemTest.Team > 1)
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && g_bHL_Privilege_Player[j] && GetClientTeam(j) == ItemTest.Team) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
						}else
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && g_bHL_Privilege_Player[j]) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
						}
					}
					case 5: //5 - Admin and Privilege All
					{
						int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
						for(int j = 1; j<= MaxClients; j++)
							if(IsValidClient(j) && IsClientConnected(j) && (g_bHL_Privilege_Player[j] || g_bIsAdmin[j])) iPlayers[iNum++] = j;
						Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
					}
					case 6: //6 - Admin and Privilege Team
					{
						if(ItemTest.Team > 1)
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && (g_bHL_Privilege_Player[j] || g_bIsAdmin[j]) && GetClientTeam(j) == ItemTest.Team) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
						}else
						{
							int iNum = 0, iPlayers[MAXPLAYERS+1] = {0,...};
							for(int j = 1; j<= MaxClients; j++)
								if(IsValidClient(j) && IsClientConnected(j) && (g_bHL_Privilege_Player[j] || g_bIsAdmin[j])) iPlayers[iNum++] = j;
							Highlight_Set(ItemTest.OwnerID, iPlayers, iNum);
						}
					}
				}
			}
		}
	}
}

stock void EWM_HLight_WRemove(int iEntity)
{
	if(g_iHL_wtype > 0 && IsValidEdict(iEntity)) Highlight_RemoveAll(iEntity);
}

stock void EWM_HLight_PRemove(int iClient)
{
	if(g_iHL_ptype > 0 && IsValidClient(iClient) && IsClientConnected(iClient) && GetClientTeam(iClient) > 1) Highlight_RemoveAll(iClient);
}

stock void EWM_HLight_UpdateRGB()
{
	static int s_iHL_Tact = 0;	
	switch(s_iHL_Tact)
	{
		case 0: if(g_iHL_RGB[0] < 255) g_iHL_RGB[0]+=RBG_STEP; else s_iHL_Tact++;
		case 1: if(g_iHL_RGB[1] < 255) g_iHL_RGB[1]+=RBG_STEP; else s_iHL_Tact++;
		case 2: if(g_iHL_RGB[2] < 255) g_iHL_RGB[2]+=RBG_STEP; else s_iHL_Tact++;
		case 3: if(g_iHL_RGB[0] > 0) g_iHL_RGB[0]-=RBG_STEP; else s_iHL_Tact++;
		case 4: if(g_iHL_RGB[1] > 0) g_iHL_RGB[1]-=RBG_STEP; else s_iHL_Tact++;
		case 5: if(g_iHL_RGB[0] < 255) g_iHL_RGB[0]+=RBG_STEP; else s_iHL_Tact++;
		case 6: if(g_iHL_RGB[2] > 0) g_iHL_RGB[2]-=RBG_STEP; else s_iHL_Tact++;
		default: s_iHL_Tact = 0;
	}
	if(g_iHL_RGB[0] > 255) g_iHL_RGB[0] = 255; else if(g_iHL_RGB[0] < 0) g_iHL_RGB[0] = 0;
	if(g_iHL_RGB[1] > 255) g_iHL_RGB[1] = 255; else if(g_iHL_RGB[1] < 0) g_iHL_RGB[1] = 0;
	if(g_iHL_RGB[2] > 255) g_iHL_RGB[2] = 255; else if(g_iHL_RGB[2] < 0) g_iHL_RGB[2] = 0;
}