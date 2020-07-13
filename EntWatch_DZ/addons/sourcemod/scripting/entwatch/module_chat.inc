#define EW_MODULE_CHAT

stock void EWM_Chat_Use(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Use, "Use", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_PickUp(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Pickup, "Pickup", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_Drop(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Drop, "Drop", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_Disconnect(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if (!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Disconnect, "Disconnect", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_Disconnect_Drop(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if (!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Disconnect, "Disconnect and drop", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_PlayerDeath(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Death, "Death", ItemTest.Color, ItemTest.Name);
}

stock void EWM_Chat_PlayerDeath_Drop(class_ItemList ItemTest, int iClient)
{
	char sAct_SteamID[32];
	GetClientAuthId(iClient, AuthId_Steam2, sAct_SteamID, sizeof(sAct_SteamID));
	ReplaceString(sAct_SteamID, sizeof(sAct_SteamID), "STEAM_", "", true);
	
	for(int iPly = 1; iPly <= MaxClients; iPly++)
		if(IsClientConnected(iPly) && IsClientInGame(iPly))
			if(!g_bTeamOnly || (g_bTeamOnly && GetClientTeam(iPly) == GetClientTeam(iClient) || !IsPlayerAlive(iPly) || g_bIsAdmin[iPly]))
				CPrintToChat(iPly,"%s%t %s%N %s(%s%s%s) %s%t %s%s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, sAct_SteamID, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_Death, "Death and drop", ItemTest.Color, ItemTest.Name);
}