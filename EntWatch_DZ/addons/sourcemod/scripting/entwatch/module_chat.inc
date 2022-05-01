#define EW_MODULE_CHAT

ConVar	g_hCvar_Chat_Admins_See;
int		g_iChatASMode = 0;

stock void EWM_Chat_OnPluginStart()
{
	g_hCvar_Chat_Admins_See	= CreateConVar("entwatch_adminchat_mode", "0", "Change AdminChat Mode (0 - All Messages, 1 - Only Pickup/Drop Items, 2 - Nothing)", _, true, 0.0, true, 2.0);
	g_iChatASMode = GetConVarInt(g_hCvar_Chat_Admins_See);
	HookConVarChange(g_hCvar_Chat_Admins_See, Cvar_Chat_Changed);
}

public void Cvar_Chat_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==g_hCvar_Chat_Admins_See)
		g_iChatASMode = GetConVarInt(convar);
}

stock void EWM_Chat_Use(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode == 0 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Use, "Use", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_PickUp(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode < 2 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Pickup, "Pickup", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_Drop(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode < 2 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Drop, "Drop", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_Disconnect(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if (!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode < 2 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Disconnect, "Disconnect", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_Disconnect_Drop(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if (!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode < 2 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Disconnect, "Disconnect and drop", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_PlayerDeath(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode < 2 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Death, "Death", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_PlayerDeath_Drop(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == ItemTest.Team || !IsPlayerAlive(iPly) || (g_iChatASMode < 2 && g_bIsAdmin[iPly])))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Death, "Death and drop", ItemTest.Color, ItemTest.Name);
}