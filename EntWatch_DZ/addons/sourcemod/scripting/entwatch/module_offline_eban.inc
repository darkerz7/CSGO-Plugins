#define EW_MODULE_OFFLINE_EBAN

#if defined EW_MODULE_EBAN

ConVar g_hCvar_OfflineClearRecords;

int g_iOfflineTimeClear = 30;

ArrayList g_OfflineArray;

class_Offline_Eban g_aMenuBuffer[MAXPLAYERS+1];

stock void EWM_OfflineEban_OnPluginStart()
{
	g_OfflineArray = new ArrayList(512);
	
	g_hCvar_OfflineClearRecords		= CreateConVar("entwatch_offline_clear_time", "30", "Time during which data is stored (1-240)", _, true, 1.0, true, 240.0);
	
	HookConVarChange(g_hCvar_OfflineClearRecords, Cvar_OfflineEBAN_Changed);
	
	RegAdminCmd("sm_eoban", EWM_OfflineEban_Command_Restrict, ADMFLAG_RCON);
	
	//Timer Checker
	CreateTimer(60.0, EWM_OfflineEban_Timer_Checker, _, TIMER_REPEAT);
}

void Cvar_OfflineEBAN_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iOfflineTimeClear = GetConVarInt(convar);
}

Action EWM_OfflineEban_Timer_Checker(Handle timer)
{
	int iCurrentTimeStamp = GetTime();
	for(int i = g_OfflineArray.Length-1; i >= 0; i--)
	{
		class_Offline_Eban OfflinePlayerTest;
		g_OfflineArray.GetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
		if(OfflinePlayerTest.TimeStamp != -1 && iCurrentTimeStamp > OfflinePlayerTest.TimeStamp) g_OfflineArray.Erase(i);
	}
	
	return Plugin_Continue;
}

public void EWM_OfflineEban_OnClientPostAdminCheck(int iClient)
{
	if(IsClientSourceTV(iClient)) return; //ignore SourceTV
	char sClient_Name[32], sClient_SteamID[64];
	int iUserID = GetClientUserId(iClient);
	GetClientName(iClient, sClient_Name, sizeof(sClient_Name));
	GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));
	bool bNotFound = true;
	for(int i = 0; i < g_OfflineArray.Length; i++)
	{
		class_Offline_Eban OfflinePlayerTest;
		g_OfflineArray.GetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
		if(StrEqual(OfflinePlayerTest.Player_SteamID, sClient_SteamID, false))
		{
			bNotFound = false;
			OfflinePlayerTest.UserID = iUserID;
			FormatEx(OfflinePlayerTest.PlayerName, sizeof(OfflinePlayerTest.PlayerName), "%s", sClient_Name);
			OfflinePlayerTest.TimeStamp = -1;
			OfflinePlayerTest.TimeStamp_Start = -1;
			FormatEx(OfflinePlayerTest.LastItem, sizeof(OfflinePlayerTest.LastItem), "None");
			g_OfflineArray.SetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
			break;
		}
	}
	if(bNotFound)
	{
		class_Offline_Eban NewOfflinePlayer;
		NewOfflinePlayer.UserID = iUserID;
		FormatEx(NewOfflinePlayer.PlayerName, sizeof(NewOfflinePlayer.PlayerName), "%s", sClient_Name);
		FormatEx(NewOfflinePlayer.Player_SteamID, sizeof(NewOfflinePlayer.Player_SteamID), "%s", sClient_SteamID);
		NewOfflinePlayer.TimeStamp = -1;
		NewOfflinePlayer.TimeStamp_Start = -1;
		FormatEx(NewOfflinePlayer.LastItem, sizeof(NewOfflinePlayer.LastItem), "None");
		g_OfflineArray.PushArray(NewOfflinePlayer, sizeof(NewOfflinePlayer));
	}
}

public void EWM_OfflineEban_OnClientDisconnect(int iClient)
{
	if(!IsValidClient(iClient) || !IsClientConnected(iClient) || IsClientSourceTV(iClient) || IsFakeClient(iClient)) return;
	
	char sClient_Name[32], sClient_SteamID[64];
	GetClientName(iClient, sClient_Name, sizeof(sClient_Name));
	GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));
	bool bNotFound = true;
	for(int i = 0; i < g_OfflineArray.Length; i++)
	{
		class_Offline_Eban OfflinePlayerTest;
		g_OfflineArray.GetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
		if(StrEqual(OfflinePlayerTest.Player_SteamID, sClient_SteamID, false))
		{
			bNotFound = false;
			FormatEx(OfflinePlayerTest.PlayerName, sizeof(OfflinePlayerTest.PlayerName), "%s", sClient_Name);
			OfflinePlayerTest.TimeStamp_Start = GetTime();
			OfflinePlayerTest.TimeStamp = OfflinePlayerTest.TimeStamp_Start+g_iOfflineTimeClear*60;
			g_OfflineArray.SetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
			break;
		}
	}
	if(bNotFound)
	{
		class_Offline_Eban NewOfflinePlayer;
		NewOfflinePlayer.UserID = GetClientUserId(iClient);
		FormatEx(NewOfflinePlayer.PlayerName, sizeof(NewOfflinePlayer.PlayerName), "%s", sClient_Name);
		FormatEx(NewOfflinePlayer.Player_SteamID, sizeof(NewOfflinePlayer.Player_SteamID), "%s", sClient_SteamID);
		NewOfflinePlayer.TimeStamp_Start = GetTime();
		NewOfflinePlayer.TimeStamp = NewOfflinePlayer.TimeStamp_Start+g_iOfflineTimeClear*60;
		FormatEx(NewOfflinePlayer.LastItem, sizeof(NewOfflinePlayer.LastItem), "None");
		g_OfflineArray.PushArray(NewOfflinePlayer, sizeof(NewOfflinePlayer));
	}
}

public void EWM_OfflineEban_UpdateItemName(int iClient, const char[] sNameItem)
{
	if(IsFakeClient(iClient)) return;
	
	char sClient_Name[32], sClient_SteamID[64];
	GetClientName(iClient, sClient_Name, sizeof(sClient_Name));
	GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));
	bool bNotFound = true;
	for(int i = 0; i < g_OfflineArray.Length; i++)
	{
		class_Offline_Eban OfflinePlayerTest;
		g_OfflineArray.GetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
		if(StrEqual(OfflinePlayerTest.Player_SteamID, sClient_SteamID, false))
		{
			bNotFound = false;
			FormatEx(OfflinePlayerTest.PlayerName, sizeof(OfflinePlayerTest.PlayerName), "%s", sClient_Name);
			FormatEx(OfflinePlayerTest.LastItem, sizeof(OfflinePlayerTest.LastItem), "%s", sNameItem);
			g_OfflineArray.SetArray(i, OfflinePlayerTest, sizeof(OfflinePlayerTest));
			break;
		}
	}
	if(bNotFound)
	{
		class_Offline_Eban NewOfflinePlayer;
		NewOfflinePlayer.UserID = GetClientUserId(iClient);
		FormatEx(NewOfflinePlayer.PlayerName, sizeof(NewOfflinePlayer.PlayerName), "%s", sClient_Name);
		FormatEx(NewOfflinePlayer.Player_SteamID, sizeof(NewOfflinePlayer.Player_SteamID), "%s", sClient_SteamID);
		NewOfflinePlayer.TimeStamp_Start = -1;
		NewOfflinePlayer.TimeStamp = -1;
		FormatEx(NewOfflinePlayer.LastItem, sizeof(NewOfflinePlayer.LastItem), "%s", sNameItem);
		g_OfflineArray.PushArray(NewOfflinePlayer, sizeof(NewOfflinePlayer));
	}
}

public void EWM_OfflineEban_BanClient(class_Offline_Eban cPlayer, int iAdmin, int iDuration, const char[] sReason)
{
	char sAdmin_Name[32];
	char sAdmin_SteamID[64];
	if(iAdmin != 0)
	{
		//Admin
		FormatEx(sAdmin_Name, sizeof(sAdmin_Name), "%N", iAdmin);
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdmin_SteamID, sizeof(sAdmin_SteamID));
	}else
	{
		//Server
		FormatEx(sAdmin_Name, sizeof(sAdmin_Name), "Console");
		FormatEx(sAdmin_SteamID, sizeof(sAdmin_SteamID), "SERVER");
	}
	int iBanDuration = iDuration;
	if(iBanDuration<0) iBanDuration = 0;
	if(iBanDuration==0)
	{
		if(g_iDBStatus == 4)
		{
			char sTQuery[1024], szAdmin_Name[32], szClient_Name[32], szReason[64];
			
			g_hEbanDB.Escape(sAdmin_Name, szAdmin_Name, sizeof(szAdmin_Name));//Admin Name to DB
			g_hEbanDB.Escape(cPlayer.PlayerName, szClient_Name, sizeof(szClient_Name));//Client Name to DB
			g_hEbanDB.Escape(sReason, szReason, sizeof(szReason));//Reason to DB
			
			int iTimeStampEBan = GetTime();
			
			FormatEx(sTQuery, sizeof(sTQuery), "INSERT INTO `EntWatch_Current_Eban` (`client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`) VALUES ('%s', '%s', '%s', '%s', '%s', %d, %d, '%s')", szClient_Name, cPlayer.Player_SteamID, szAdmin_Name, sAdmin_SteamID, g_SchemeConfig.Server_Name, iBanDuration, iTimeStampEBan, szReason);
			SQL_TQuery(g_hEbanDB, EWM_OfflineEban_SQLTCallBackBan, sTQuery,0);
		}
		LogAction(iAdmin, -1, "\"%L\" offline restricted \"%s [%s]\" permanently. Reason: %s", iAdmin, cPlayer.PlayerName, cPlayer.Player_SteamID, sReason);
		CPrintToChatAll("%s%t %s%s %s%t %s%s [%s] %s%t. %s%t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, sAdmin_Name, g_SchemeConfig.Color_Disabled, "Offline Restricted", g_SchemeConfig.Color_Name, cPlayer.PlayerName, cPlayer.Player_SteamID, g_SchemeConfig.Color_Disabled, "Permanently", g_SchemeConfig.Color_Warning, "Reason", sReason);
	} else
	{
		if(g_iDBStatus == 4)
		{
			char sTQuery[1024], szAdmin_Name[32], szClient_Name[32], szReason[64];
			
			g_hEbanDB.Escape(sAdmin_Name, szAdmin_Name, sizeof(szAdmin_Name));//Admin Name to DB
			g_hEbanDB.Escape(cPlayer.PlayerName, szClient_Name, sizeof(szClient_Name));//Client Name to DB
			g_hEbanDB.Escape(sReason, szReason, sizeof(szReason));//Reason to DB
			
			int iTimeStampEBan = GetTime()+iBanDuration*60;
			
			FormatEx(sTQuery, sizeof(sTQuery), "INSERT INTO `EntWatch_Current_Eban` (`client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`) VALUES ('%s', '%s', '%s', '%s', '%s', %d, %d, '%s')", szClient_Name, cPlayer.Player_SteamID, szAdmin_Name, sAdmin_SteamID, g_SchemeConfig.Server_Name, iBanDuration, iTimeStampEBan, szReason);
			SQL_TQuery(g_hEbanDB, EWM_OfflineEban_SQLTCallBackBan, sTQuery,0);
		}
		
		LogAction(iAdmin, -1, "\"%L\" offline restricted \"%s [%s]\" for %d minutes. Reason: %s", iAdmin, cPlayer.PlayerName, cPlayer.Player_SteamID, iBanDuration, sReason);
		CPrintToChatAll("%s%t %s%s %s%t %s%s [%s] %s%t. %s%t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, sAdmin_Name, g_SchemeConfig.Color_Disabled, "Offline Restricted", g_SchemeConfig.Color_Name, cPlayer.PlayerName, cPlayer.Player_SteamID, g_SchemeConfig.Color_Enabled, "For Minutes", iBanDuration, g_SchemeConfig.Color_Warning, "Reason", sReason);
	}
}

void EWM_OfflineEban_SQLTCallBackBan(Handle hDatabase, Handle hResults, const char[] sError, any data)
{
	if(sError[0]) LogError("[Offline EBan DB] SQL CallBack Offline Ban Error: %s", sError);
		else LogMessage("[Offline EBan DB] Successful Offline Ban");
}

void EWM_OfflineEban_PlayerList(int iClient)
{
	Menu hMenu = CreateMenu(EWM_OfflineEban_PlayerList_Handler);
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "List of Disconnected Players", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitButton = true;
	int iCurrentTime = GetTime();
	bool bNotFound = true;
	for(int i = 0; i<g_OfflineArray.Length; i++)
	{
		class_Offline_Eban ItemTest;
		g_OfflineArray.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.TimeStamp != -1)
		{
			char sIndexItem[32], sItemName[64];
			FormatEx(sItemName, sizeof(sItemName), "%s (#%i|%i %T)", ItemTest.PlayerName, ItemTest.UserID, (iCurrentTime-ItemTest.TimeStamp_Start)/60, "Minutes Ago", iClient);
			FormatEx(sIndexItem, sizeof(sIndexItem), "%d", ItemTest.UserID);
			hMenu.AddItem(sIndexItem, sItemName);
			bNotFound = false;
		}
	}
	if(bNotFound)
	{
		FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "No Players", iClient);
		hMenu.AddItem("", sMenuTranslate, ITEMDRAW_DISABLED);
	}
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_OfflineEban_Player(int iClient)
{
	Menu hMenu = CreateMenu(EWM_OfflineEban_Player_Handler);
	char sMenuTranslate[128];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T:", "EW_Tag", iClient, "Info Offline Player", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T: %s #%i (%s)", "Player", iClient, g_aMenuBuffer[iClient].PlayerName, g_aMenuBuffer[iClient].UserID, g_aMenuBuffer[iClient].Player_SteamID);
	hMenu.AddItem("", sMenuTranslate, ITEMDRAW_DISABLED);
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %i %T", "Came out", iClient, (GetTime()-g_aMenuBuffer[iClient].TimeStamp_Start)/60, "Minutes Ago", iClient);
	hMenu.AddItem("", sMenuTranslate, ITEMDRAW_DISABLED);
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T: %s", "Last Item", iClient, g_aMenuBuffer[iClient].LastItem);
	hMenu.AddItem("", sMenuTranslate, ITEMDRAW_DISABLED);
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T", "EBan a Player", iClient);
	hMenu.AddItem("777", sMenuTranslate);
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_OfflineEban_Duration(int iClient)
{
	Menu hMenu = CreateMenu(EWM_OfflineEban_Duration_Handler);
	char sMenuTranslate[128], sMenuTemp[64];
	FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %s #%i (%s)", "EW_Tag", iClient, "EBan Duration for", iClient, g_aMenuBuffer[iClient].PlayerName, g_aMenuBuffer[iClient].UserID, g_aMenuBuffer[iClient].Player_SteamID);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "10 %T", "Minutes", iClient);
	hMenu.AddItem("10", sMenuTemp);
	
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Hour", iClient);
	hMenu.AddItem("60", sMenuTemp);
	
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Day", iClient);
	hMenu.AddItem("1440", sMenuTemp);
	
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Week", iClient);
	hMenu.AddItem("10080", sMenuTemp);
	
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "1 %T", "Month", iClient);
	hMenu.AddItem("40320", sMenuTemp);
	
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Permanently", iClient);
	hMenu.AddItem("0", sMenuTemp);
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

void EWM_OfflineEban_Reason(int iClient, int iDuration)
{
	Menu hMenu = CreateMenu(EWM_OfflineEban_Reason_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[96];
	if(iDuration == 0) FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %s #%i (%s) [%T]", "EW_Tag", iClient, "EBan Reason for", iClient, g_aMenuBuffer[iClient].PlayerName, g_aMenuBuffer[iClient].UserID, g_aMenuBuffer[iClient].Player_SteamID, "Permanently", iClient);
		else FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %s #%i (%s) [%i %T]", "EW_Tag", iClient, "EBan Reason for", iClient, g_aMenuBuffer[iClient].PlayerName, g_aMenuBuffer[iClient].UserID, g_aMenuBuffer[iClient].Player_SteamID, iDuration, "Minutes", iClient);
	hMenu.SetTitle(sMenuTranslate);
	hMenu.ExitBackButton = true;
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Item misuse");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Item misuse", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Trolling on purpose");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Trolling on purpose", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Throwing item away");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Throwing item away", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Not using an item");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not using an item", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Trimming team");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Trimming team", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Not listening to leader");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not listening to leader", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Spamming an item");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Spamming an item", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%s", iDuration, "Other");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Other", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int EWM_OfflineEban_PlayerList_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			int iItemIndex = StringToInt(sOption);
			bool bFound = false;
			for(int i = 0; i<g_OfflineArray.Length; i++)
			{
				class_Offline_Eban ItemTest;
				g_OfflineArray.GetArray(i, ItemTest, sizeof(ItemTest));
				if(iItemIndex == ItemTest.UserID)
				{
					bFound = true;
					g_aMenuBuffer[iClient].UserID = ItemTest.UserID;
					FormatEx(g_aMenuBuffer[iClient].PlayerName, 32, "%s", ItemTest.PlayerName);
					FormatEx(g_aMenuBuffer[iClient].Player_SteamID, 64, "%s", ItemTest.Player_SteamID);
					g_aMenuBuffer[iClient].TimeStamp = ItemTest.TimeStamp;
					g_aMenuBuffer[iClient].TimeStamp_Start = ItemTest.TimeStamp_Start;
					FormatEx(g_aMenuBuffer[iClient].LastItem, 32, "%s", ItemTest.LastItem);
					break;
				}
			}
			if(bFound)
			{
				EWM_OfflineEban_Player(iClient);
			}else
			{
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
				delete hMenu;
			}
		}
	}
}

public int EWM_OfflineEban_Player_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_OfflineEban_PlayerList(iClient);
		case MenuAction_Select:
		{
			char sOption[32];
			hMenu.GetItem(iParam2, sOption, sizeof(sOption));
			if(StringToInt(sOption) == 777) EWM_OfflineEban_Duration(iClient);
		}
	}
}

public int EWM_OfflineEban_Duration_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_OfflineEban_Player(iClient);
		case MenuAction_Select:
		{
			char sSelected[64];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			int iDuration = StringToInt(sSelected);
			bool bAccessDuration = true;
			if (iDuration == 0)
			{
				//Check if admin has permission
				if (!CheckCommandAccess(iClient, "sm_eban_perm", ADMFLAG_ROOT))
				{
					CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Not have permission rEBan");
					bAccessDuration = false;
				}
			}else if(iDuration >= 720)
			{
				//Check if admin has permission
				if (!CheckCommandAccess(iClient, "sm_eban_long", ADMFLAG_ROOT))
				{
					CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Not have permission lEBan");
					bAccessDuration = false;
				}
			}
			if(bAccessDuration) EWM_OfflineEban_Reason(iClient, iDuration);
		}
	}
}

public int EWM_OfflineEban_Reason_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel: if (iParam2 == MenuCancel_ExitBack) EWM_OfflineEban_Duration(iClient);
		case MenuAction_Select:
		{
			char sSelected[64], Explode_sParam[2][64], sReason[32];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 2, 64);
			int iDuration = StringToInt(Explode_sParam[0]);
			FormatEx(sReason, sizeof(sReason), "%s", Explode_sParam[1]);
			EWM_OfflineEban_BanClient(g_aMenuBuffer[iClient], iClient, iDuration, sReason);
		}
	}
}

//-------------------------------------------------------
// Purpose: Offline Ban a client
//-------------------------------------------------------
public Action EWM_OfflineEban_Command_Restrict(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient))) EWM_OfflineEban_PlayerList(iClient);
	return Plugin_Handled;
}
#endif