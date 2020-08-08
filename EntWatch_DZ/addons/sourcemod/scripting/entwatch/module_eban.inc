#define EW_MODULE_EBAN

#define EW_EBAN_ENTWATCH_SECTION "EntWatch"

//-------------------------------------------------------
// Purpose: Plugin settings
//-------------------------------------------------------
ConVar	g_hCvar_Default_BanTime,
		g_hCvar_Default_BanReason,
		g_hCvar_Keep_Expired_Bans,
		g_hCvar_Use_Reason_Menu;

//-------------------------------------------------------
// Purpose: Plugin Variables
//-------------------------------------------------------
class_ClientSettings_EBan g_EbanClients[MAXPLAYERS+1];
bool g_bKeepExpiredBans = true;

Database g_hEbanDB;
int g_iDBStatus = 0; // 0 - Def., 1 - Reconnect, 2 - Unknown Driver, 3 - Create Table, 4 - Ready to Query

stock void EWM_Eban_OnPluginStart()
{
	g_hCvar_Default_BanTime		= CreateConVar("entwatch_bantime", "0", "Default ban time (0-43200)", _, true, 0.0, true, 43200.0);
	g_hCvar_Default_BanReason	= CreateConVar("entwatch_banreason", "Item misuse", "Default ban reason.", _);
	g_hCvar_Keep_Expired_Bans	= CreateConVar("entwatch_keep_expired_ban", "1", "Enable/Disable keep expired bans.", _, true, 0.0, true, 1.0);
	g_hCvar_Use_Reason_Menu		= CreateConVar("entwatch_use_reason_menu", "0", "Enable/Disable menu if the admin has not indicated a reason", _, true, 0.0, true, 1.0);

	HookConVarChange(g_hCvar_Keep_Expired_Bans, Cvar_EBAN_Changed);
	
	RegConsoleCmd("sm_status", EWM_Eban_Command_Status);
	
	RegAdminCmd("sm_eban", EWM_Eban_Command_Restrict, ADMFLAG_BAN);
	RegAdminCmd("sm_eunban", EWM_Eban_Command_Unrestrict, ADMFLAG_BAN);
	RegAdminCmd("sm_ebanlist", EWM_Eban_Command_EBanlist, ADMFLAG_BAN);
	
	Database.Connect(EWM_Eban_ConnectCallBack, EW_EBAN_ENTWATCH_SECTION);
	//Timer Checker
	CreateTimer(60.0, EWM_Eban_Timer_Checker, _, TIMER_REPEAT);
}

void Cvar_EBAN_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bKeepExpiredBans = GetConVarBool(convar);
}

void EWM_Eban_ConnectCallBack(Database hDatabase, const char[] sError, any data)
{
	if (hDatabase == null)	// Fail Connect
	{
		LogError("[EBan DB] Database failure: %s, ReConnect after 60 sec", sError);
		g_iDBStatus = 1; //ReConnect
		return;
	}
	g_hEbanDB = hDatabase;
	LogMessage("[EBan DB] Successful connection to DB");
	EWM_Eban_CreateTables(); // Create Tables
	g_hEbanDB.SetCharset("utf8"); // Set Charset UTF8
}

void EWM_Eban_CreateTables()
{
	char sConnectDriverDB[16];
	g_hEbanDB.Driver.GetIdentifier(sConnectDriverDB, sizeof(sConnectDriverDB));
	if(strcmp(sConnectDriverDB, "mysql") == 0)
	{
		g_iDBStatus = 3;
		//Create MySQL Tables
		char sSQL_Query[1024];
		Transaction T_CreateTables = SQL_CreateTransaction();
		FormatEx(sSQL_Query, sizeof(sSQL_Query), "CREATE TABLE IF NOT EXISTS `EntWatch_Current_Eban`(	`id` int(10) unsigned NOT NULL auto_increment, \
																										`client_name` varchar(32) NOT NULL, \
																										`client_steamid` varchar(64) NOT NULL, \
																										`admin_name` varchar(32) NOT NULL, \
																										`admin_steamid` varchar(64) NOT NULL, \
																										`server` varchar(64), \
																										`duration` int unsigned NOT NULL, \
																										`timestamp_issued` int NOT NULL, \
																										`reason` varchar(64), \
																										`reason_unban` varchar(64), \
																										`admin_name_unban` varchar(32), \
																										`admin_steamid_unban` varchar(64), \
																										`timestamp_unban` int, \
																										PRIMARY KEY (id))");
		T_CreateTables.AddQuery(sSQL_Query);
		FormatEx(sSQL_Query, sizeof(sSQL_Query), "CREATE TABLE IF NOT EXISTS `EntWatch_Old_Eban`(	`id` int(10) unsigned NOT NULL auto_increment, \
																									`client_name` varchar(32) NOT NULL, \
																									`client_steamid` varchar(64) NOT NULL, \
																									`admin_name` varchar(32) NOT NULL, \
																									`admin_steamid` varchar(64) NOT NULL, \
																									`server` varchar(64), \
																									`duration` int unsigned NOT NULL, \
																									`timestamp_issued` int NOT NULL, \
																									`reason` varchar(64), \
																									`reason_unban` varchar(64), \
																									`admin_name_unban` varchar(32), \
																									`admin_steamid_unban` varchar(64), \
																									`timestamp_unban` int, \
																									PRIMARY KEY (id))");
		T_CreateTables.AddQuery(sSQL_Query);
		SQL_ExecuteTransaction(g_hEbanDB, T_CreateTables, EWM_Eban_SQLCreateTables_Success, EWM_Eban_SQLCreateTables_Error, _, DBPrio_High);
	} else if(strcmp(sConnectDriverDB, "sqlite") == 0)
	{
		g_iDBStatus = 3;
		//Create SQLite Tables
		char sSQL_Query[1024];
		Transaction T_CreateTables = SQL_CreateTransaction();
		FormatEx(sSQL_Query, sizeof(sSQL_Query), "CREATE TABLE IF NOT EXISTS `EntWatch_Current_Eban`(	`id` INTEGER PRIMARY KEY AUTOINCREMENT, \
																										`client_name` varchar(32) NOT NULL, \
																										`client_steamid` varchar(64) NOT NULL, \
																										`admin_name` varchar(32) NOT NULL, \
																										`admin_steamid` varchar(64) NOT NULL, \
																										`server` varchar(64), \
																										`duration` INTEGER NOT NULL, \
																										`timestamp_issued` INTEGER NOT NULL, \
																										`reason` varchar(64), \
																										`reason_unban` varchar(64), \
																										`admin_name_unban` varchar(32), \
																										`admin_steamid_unban` varchar(64), \
																										`timestamp_unban` INTEGER)");
		T_CreateTables.AddQuery(sSQL_Query);																							
		FormatEx(sSQL_Query, sizeof(sSQL_Query), "CREATE TABLE IF NOT EXISTS `EntWatch_Old_Eban`(	`id` INTEGER PRIMARY KEY AUTOINCREMENT, \
																									`client_name` varchar(32) NOT NULL, \
																									`client_steamid` varchar(64) NOT NULL, \
																									`admin_name` varchar(32) NOT NULL, \
																									`admin_steamid` varchar(64) NOT NULL, \
																									`server` varchar(64), \
																									`duration` INTEGER NOT NULL, \
																									`timestamp_issued` INTEGER NOT NULL, \
																									`reason` varchar(64), \
																									`reason_unban` varchar(64), \
																									`admin_name_unban` varchar(32), \
																									`admin_steamid_unban` varchar(64), \
																									`timestamp_unban` INTEGER)");
		T_CreateTables.AddQuery(sSQL_Query);
		SQL_ExecuteTransaction(g_hEbanDB, T_CreateTables, EWM_Eban_SQLCreateTables_Success, EWM_Eban_SQLCreateTables_Error, _, DBPrio_High);
	} else
	{
		g_iDBStatus = 2;
		LogError("[EBan] Unknown Driver: %s, cannot create tables.", sConnectDriverDB);
	}
}

void EWM_Eban_SQLCreateTables_Success(Database hDatabase, any Data, int iNumQueries, Handle[] hResults, any[] QueryData)
{
	g_iDBStatus = 4;
	LogMessage("[EBan DB] DB Ready");
	EWM_Eban_CleanData_All();
}

void EWM_Eban_SQLCreateTables_Error(Database hDatabase, any Data, int iNumQueries, const  char[] sError, int iFailIndex, any[] QueryData)
{
	g_iDBStatus = 1;
	LogError("[EBan DB] SQL CreateTables Error: %s", sError);
}

public void EWM_Eban_BanClient(int iClient, int iAdmin, int iDuration, const char[] sReason)
{
	if(!g_EbanClients[iClient].Banned)
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
		if(iBanDuration<-1) iBanDuration = -1;
		if(iBanDuration==-1)
		{
			//Temporary
			g_EbanClients[iClient].Banned = true;
			FormatEx(g_EbanClients[iClient].Admin_Name, 32, "%s", sAdmin_Name);
			FormatEx(g_EbanClients[iClient].Admin_SteamID, 64, "%s", sAdmin_SteamID);
			g_EbanClients[iClient].Duration = iBanDuration;
			g_EbanClients[iClient].TimeStamp_Issued = GetTime();
			FormatEx(g_EbanClients[iClient].Reason, 64, "%s", sReason);
			LogAction(iAdmin, iClient, "\"%L\" restricted \"%L\" temporary. Reason: %s", iAdmin, iClient, sReason);
			CPrintToChatAll("%s%t %s%s %s%t %s%N% %s%t. %s%t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, sAdmin_Name, g_SchemeConfig.Color_Disabled, "Restricted", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Enabled, "Temporary", g_SchemeConfig.Color_Warning, "Reason", sReason);
		}else if(iBanDuration == 0)
		{
			//Wesker EDIT -- Restrict perma bans with command override
			if(iAdmin != 0)
			{
				//Check if admin has permission
				if (!CheckCommandAccess(iAdmin, "sm_eban_perm", ADMFLAG_ROOT))
				{
					CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Not have permission pEBan");
					return;
				}
			}
			//Permament
			g_EbanClients[iClient].Banned = true;
			FormatEx(g_EbanClients[iClient].Admin_Name, 32, "%s", sAdmin_Name);
			FormatEx(g_EbanClients[iClient].Admin_SteamID, 64, "%s", sAdmin_SteamID);
			g_EbanClients[iClient].Duration = iBanDuration;
			g_EbanClients[iClient].TimeStamp_Issued = GetTime();
			FormatEx(g_EbanClients[iClient].Reason, 64, "%s", sReason);
			//Save to DB
			if(g_iDBStatus == 4)
			{
				char sTQuery[1024], szAdmin_Name[32], sClient_Name[32], szClient_Name[32], sClient_SteamID[64], szReason[64];
				
				g_hEbanDB.Escape(sAdmin_Name, szAdmin_Name, sizeof(szAdmin_Name));//Admin Name to DB
				GetClientName(iClient, sClient_Name, MAX_NAME_LENGTH);//Get Client Name
				g_hEbanDB.Escape(sClient_Name, szClient_Name, sizeof(szClient_Name));//Client Name to DB
				GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));//Client SteamId to DB
				g_hEbanDB.Escape(sReason, szReason, sizeof(szReason));//Reason to DB
				
				FormatEx(sTQuery, sizeof(sTQuery), "INSERT INTO `EntWatch_Current_Eban` (`client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`) VALUES ('%s', '%s', '%s', '%s', '%s', %d, %d, '%s')", szClient_Name, sClient_SteamID, szAdmin_Name, sAdmin_SteamID, g_SchemeConfig.Server_Name, iBanDuration, g_EbanClients[iClient].TimeStamp_Issued, szReason);
				SQL_TQuery(g_hEbanDB, EWM_Eban_SQLTCallBackBan, sTQuery,0);
			}
			LogAction(iAdmin, iClient, "\"%L\" restricted \"%L\" permanently. Reason: %s", iAdmin, iClient, sReason);
			CPrintToChatAll("%s%t %s%s %s%t %s%N %s%t. %s%t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, sAdmin_Name, g_SchemeConfig.Color_Disabled, "Restricted", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Disabled, "Permanently", g_SchemeConfig.Color_Warning, "Reason", sReason);
		}else
		{
			//Wesker EDIT -- Restrict longer bans with command override
			if(iAdmin != 0 && iBanDuration >= 720)
			{
				//Check if admin has permission
				if (!CheckCommandAccess(iAdmin, "sm_eban_long", ADMFLAG_ROOT))
				{
					CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Not have permission lEBan");
					return;
				}
			}
			//Duration
			g_EbanClients[iClient].Banned = true;
			FormatEx(g_EbanClients[iClient].Admin_Name, 32, "%s", sAdmin_Name);
			FormatEx(g_EbanClients[iClient].Admin_SteamID, 64, "%s", sAdmin_SteamID);
			g_EbanClients[iClient].Duration = iBanDuration;
			g_EbanClients[iClient].TimeStamp_Issued = GetTime()+iBanDuration*60;
			FormatEx(g_EbanClients[iClient].Reason, 64, "%s", sReason);
			//Save to DB
			if(g_iDBStatus == 4)
			{
				char sTQuery[1024], szAdmin_Name[32], sClient_Name[32], szClient_Name[32], sClient_SteamID[64], szReason[64];
				
				g_hEbanDB.Escape(sAdmin_Name, szAdmin_Name, sizeof(szAdmin_Name));//Admin Name to DB
				GetClientName(iClient, sClient_Name, MAX_NAME_LENGTH);//Get Client Name
				g_hEbanDB.Escape(sClient_Name, szClient_Name, sizeof(szClient_Name));//Client Name to DB
				GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));//Client SteamId to DB
				g_hEbanDB.Escape(sReason, szReason, sizeof(szReason));//Reason to DB
				
				FormatEx(sTQuery, sizeof(sTQuery), "INSERT INTO `EntWatch_Current_Eban` (`client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`) VALUES ('%s', '%s', '%s', '%s', '%s', %d, %d, '%s')", szClient_Name, sClient_SteamID, szAdmin_Name, sAdmin_SteamID, g_SchemeConfig.Server_Name, iBanDuration, g_EbanClients[iClient].TimeStamp_Issued, szReason);
				SQL_TQuery(g_hEbanDB, EWM_Eban_SQLTCallBackBan, sTQuery,0);
			}
			
			LogAction(iAdmin, iClient, "\"%L\" restricted \"%L\" for %d minutes. Reason: %s", iAdmin, iClient, iBanDuration, sReason);
			CPrintToChatAll("%s%t %s%s %s%t %s%N %s%t. %s%t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, sAdmin_Name, g_SchemeConfig.Color_Disabled, "Restricted", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Enabled, "For Minutes", iBanDuration, g_SchemeConfig.Color_Warning, "Reason", sReason);
		}
		
		#if defined EW_MODULE_FORWARDS
		Call_StartForward(g_hOnBanForward);
		Call_PushCell(iAdmin);
		Call_PushCell(iBanDuration);
		Call_PushCell(iClient);
		Call_PushString(g_EbanClients[iClient].Reason);
		Call_Finish();
		#endif
	} else
	{
		if(IsValidClient(iAdmin) && IsClientConnected(iAdmin))
		{
			CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Already EBanned");
			CPrintToChat(iAdmin, "%s%t %s%t %s%N %s%t %t %s%s%s(%s%s%s)", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, "Restricted By", "Admin", g_SchemeConfig.Color_Name, g_EbanClients[iClient].Admin_Name, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, g_EbanClients[iClient].Admin_SteamID, g_SchemeConfig.Color_Warning);
		}
	}
}

void EWM_Eban_SQLTCallBackBan(Handle hDatabase, Handle hResults, const char[] sError, any data)
{
	if(sError[0]) LogError("[EBan DB] SQL CallBack Ban Error: %s", sError);
		else LogMessage("[EBan DB] Successful Ban");
}

public void EWM_Eban_UnBanClient(int iClient, int iAdmin, const char[] sReason)
{
	char sAdmin_Name[32];
	char sAdmin_SteamID[64];
	if (iAdmin != 0)
	{
		//WESKER EDIT -- Restrict perma unbans with command override
		int iBanDuration = g_EbanClients[iClient].Duration;
		if (iBanDuration == 0)
		{
			//Check if admin has permission
			if (!CheckCommandAccess(iAdmin, "sm_eban_perm", ADMFLAG_ROOT))
			{
				CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Not have permission rEBan");
				return;
			}
		}else if(iBanDuration >= 720)
		{
			//Check if admin has permission
			if (!CheckCommandAccess(iAdmin, "sm_eban_long", ADMFLAG_ROOT))
			{
				CPrintToChat(iAdmin, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Not have permission lEBan");
				return;
			}
		}
		
		//Admin
		FormatEx(sAdmin_Name, sizeof(sAdmin_Name), "%N", iAdmin);
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdmin_SteamID, sizeof(sAdmin_SteamID));
	}else
	{
		//Server
		FormatEx(sAdmin_Name, sizeof(sAdmin_Name), "Console");
		FormatEx(sAdmin_SteamID, sizeof(sAdmin_SteamID), "SERVER");
	}
	
	if(g_iDBStatus == 4)
	{
		char sSQL_Query[1024], sClient_SteamID[64], szReason[64], szAdmin_Name[32];
		GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));
		g_hEbanDB.Escape(sReason, szReason, sizeof(szReason));//Reason Unban to DB
		g_hEbanDB.Escape(sAdmin_Name, szAdmin_Name, sizeof(szAdmin_Name));//Admin Name Unban to DB
		
		Transaction T_UnBan = SQL_CreateTransaction();
		
		if(g_bKeepExpiredBans)
		{
			FormatEx(sSQL_Query, sizeof(sSQL_Query), "UPDATE `EntWatch_Current_Eban` SET `reason_unban`='%s', `admin_name_unban`='%s', `admin_steamid_unban`='%s', `timestamp_unban`=%d \
														WHERE `client_steamid`='%s' and `server`='%s' and `admin_steamid_unban` IS NULL", szReason, szAdmin_Name, sAdmin_SteamID, GetTime(), sClient_SteamID, g_SchemeConfig.Server_Name);
			T_UnBan.AddQuery(sSQL_Query);
			FormatEx(sSQL_Query, sizeof(sSQL_Query), "INSERT INTO `EntWatch_Old_Eban` (`client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`, `reason_unban`, `admin_name_unban`, `admin_steamid_unban`, `timestamp_unban`) \
														SELECT `client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`, `reason_unban`, `admin_name_unban`, `admin_steamid_unban`, `timestamp_unban` FROM `EntWatch_Current_Eban` \
														WHERE `client_steamid`='%s' and `server`='%s'", sClient_SteamID, g_SchemeConfig.Server_Name);
			T_UnBan.AddQuery(sSQL_Query);
		}
		
		FormatEx(sSQL_Query, sizeof(sSQL_Query), "DELETE FROM `EntWatch_Current_Eban` \
													WHERE `client_steamid`='%s' and `server`='%s'", sClient_SteamID, g_SchemeConfig.Server_Name);
		T_UnBan.AddQuery(sSQL_Query);
		SQL_ExecuteTransaction(g_hEbanDB, T_UnBan, EWM_Eban_SQLUnBan_Success, EWM_Eban_SQLUnBan_Error, _, DBPrio_Normal);
	}
	
	EWM_Eban_CleanData_Client(iClient);

	#if defined EW_MODULE_FORWARDS
	Call_StartForward(g_hOnUnbanForward);
	Call_PushCell(iAdmin);
	Call_PushCell(iClient);
	Call_PushString(sReason);
	Call_Finish();
	#endif

	EWM_Eban_Update_Client(iClient);
	
	LogAction(iAdmin, iClient, "\"%L\" unrestricted \"%L\". Reason: %s", iAdmin, iClient, sReason);
	CPrintToChatAll("%s%t %s%s %s%t %s%N%. %s%t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Name, sAdmin_Name, g_SchemeConfig.Color_Enabled, "Unrestricted", g_SchemeConfig.Color_Name, iClient, g_SchemeConfig.Color_Warning, "Reason", sReason);
}

void EWM_Eban_SQLUnBan_Success(Database hDatabase, any Data, int iNumQueries, Handle[] hResults, any[] QueryData)
{
	LogMessage("[EBan DB] Successful UnBan");
}

void EWM_Eban_SQLUnBan_Error(Database hDatabase, any Data, int iNumQueries, const  char[] sError, int iFailIndex, any[] QueryData)
{
	LogError("[EBan DB] SQL UnBan Error: %s", sError);
}

void EWM_Eban_Update_Client(int iClient)
{
	if(g_iDBStatus == 4)
	{
		char sTQuery[1024], sClient_SteamID[64];
		GetClientAuthId(iClient, AuthId_Steam2, sClient_SteamID, sizeof(sClient_SteamID));
		FormatEx(sTQuery, sizeof(sTQuery), "SELECT `admin_name`, `admin_steamid`, `duration`, `timestamp_issued`, `reason` FROM `EntWatch_Current_Eban` \
												WHERE `client_steamid`='%s' and `server`='%s'", sClient_SteamID, g_SchemeConfig.Server_Name);
		SQL_TQuery(g_hEbanDB, EWM_Eban_SQLTCallBackUpdate, sTQuery, GetClientUserId(iClient));
	}
}

void EWM_Eban_SQLTCallBackUpdate(Handle hDatabase, Handle hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("[EBan DB] SQL CallBack Update Error: %s", sError);
	}
	else
	{
		int iClient = GetClientOfUserId(iUserID);
		if(iClient && IsClientInGame(iClient))
		{
			bool bBanFound = false;
			class_ClientSettings_EBan ClientBuffer, ClientSet;
			while(SQL_FetchRow(hResults))
			{
				bBanFound = true;
				SQL_FetchString(hResults, 0, ClientBuffer.Admin_Name, sizeof(ClientBuffer.Admin_Name));
				SQL_FetchString(hResults, 1, ClientBuffer.Admin_SteamID, sizeof(ClientBuffer.Admin_SteamID));
				ClientBuffer.Duration = SQL_FetchInt(hResults, 2);
				ClientBuffer.TimeStamp_Issued = SQL_FetchInt(hResults, 3);
				SQL_FetchString(hResults, 4, ClientBuffer.Reason, sizeof(ClientBuffer.Reason));
				if(ClientBuffer.Duration == 0)
				{
					//Found Permament
					FormatEx(ClientSet.Admin_Name, 32, "%s", ClientBuffer.Admin_Name);
					FormatEx(ClientSet.Admin_SteamID, 64, "%s", ClientBuffer.Admin_SteamID);
					ClientSet.Duration = 0;
					ClientSet.TimeStamp_Issued = ClientBuffer.TimeStamp_Issued;
					FormatEx(ClientSet.Reason, 64, "%s", ClientBuffer.Reason);
					break;
				}else
				{
					//Found Duration
					if(ClientSet.Duration < ClientBuffer.Duration)
					{
						FormatEx(ClientSet.Admin_Name, 32, "%s", ClientBuffer.Admin_Name);
						FormatEx(ClientSet.Admin_SteamID, 64, "%s", ClientBuffer.Admin_SteamID);
						ClientSet.Duration = ClientBuffer.Duration;
						ClientSet.TimeStamp_Issued = ClientBuffer.TimeStamp_Issued;
						FormatEx(ClientSet.Reason, 64, "%s", ClientBuffer.Reason);
					}
				}
			}
			if(bBanFound)
			{
				g_EbanClients[iClient].Banned = true;
				FormatEx(g_EbanClients[iClient].Admin_Name, 32, "%s", ClientSet.Admin_Name);
				FormatEx(g_EbanClients[iClient].Admin_SteamID, 64, "%s", ClientSet.Admin_SteamID);
				g_EbanClients[iClient].Duration = ClientSet.Duration;
				g_EbanClients[iClient].TimeStamp_Issued = ClientSet.TimeStamp_Issued;
				FormatEx(g_EbanClients[iClient].Reason, 64, "%s", ClientSet.Reason);
			} else
			{
				g_EbanClients[iClient].Banned = false;
				FormatEx(g_EbanClients[iClient].Admin_Name, 32, "");
				FormatEx(g_EbanClients[iClient].Admin_SteamID, 64, "");
				g_EbanClients[iClient].Duration = 0;
				g_EbanClients[iClient].TimeStamp_Issued = 0;
				FormatEx(g_EbanClients[iClient].Reason, 64, "");
			}
		}
	}
}

void EWM_Eban_Offline_Unban(int iTime)
{
	if(g_iDBStatus == 4)
	{
		char sTQuery[1024];
		FormatEx(sTQuery, sizeof(sTQuery), "SELECT `id` FROM `EntWatch_Current_Eban` \
												WHERE `server`='%s' and `duration` > 0 and `timestamp_issued` < %d", g_SchemeConfig.Server_Name, iTime);
		SQL_TQuery(g_hEbanDB, EWM_Eban_SQLTCallBackOfflineUnban, sTQuery, iTime);
	}
}

void EWM_Eban_SQLTCallBackOfflineUnban(Handle hDatabase, Handle hResults, const char[] sError, any iTime)
{
	if(sError[0])
	{
		LogError("[EBan DB] SQL CallBack Update Error: %s", sError);
	}
	else
	{
		int iCurrentID = 0;
		char sSQL_Query[1024];
		while(SQL_FetchRow(hResults))
		{
			iCurrentID = SQL_FetchInt(hResults, 0);
			Transaction T_UnBan = SQL_CreateTransaction();
		
			if(g_bKeepExpiredBans)
			{
				FormatEx(sSQL_Query, sizeof(sSQL_Query), "UPDATE `EntWatch_Current_Eban` SET `reason_unban`='Expired', `admin_name_unban`='Console', `admin_steamid_unban`='SERVER', `timestamp_unban`=%d \
															WHERE `id`=%d", iTime, iCurrentID);
				T_UnBan.AddQuery(sSQL_Query);
				FormatEx(sSQL_Query, sizeof(sSQL_Query), "INSERT INTO `EntWatch_Old_Eban` (`client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`, `reason_unban`, `admin_name_unban`, `admin_steamid_unban`, `timestamp_unban`) \
															SELECT `client_name`, `client_steamid`, `admin_name`, `admin_steamid`, `server`, `duration`, `timestamp_issued`, `reason`, `reason_unban`, `admin_name_unban`, `admin_steamid_unban`, `timestamp_unban` FROM `EntWatch_Current_Eban` \
															WHERE `id`=%d", iCurrentID);
				T_UnBan.AddQuery(sSQL_Query);
			}
			
			FormatEx(sSQL_Query, sizeof(sSQL_Query), "DELETE FROM `EntWatch_Current_Eban` \
														WHERE `id`=%d", iCurrentID);
			T_UnBan.AddQuery(sSQL_Query);
			SQL_ExecuteTransaction(g_hEbanDB, T_UnBan, _, _, _, DBPrio_Normal);
		}
	}
}

Action EWM_Eban_Timer_Checker(Handle timer)
{
	if(g_iDBStatus>0)
	{
		if(g_iDBStatus == 4)// Success Connect
		{
			int iCurrentTimeStamp = GetTime();
			for(int i=1; i<MaxClients+1; i++)
			{
				if(!IsClientInGame(i)) continue;
				
				if(g_EbanClients[i].Banned)
				{
					if(g_EbanClients[i].Duration>0)
					{
						if(iCurrentTimeStamp>g_EbanClients[i].TimeStamp_Issued)
						{
							//unban
							EWM_Eban_UnBanClient(i, 0, "Expired");
						}
					}
				}
			}
			EWM_Eban_Offline_Unban(iCurrentTimeStamp);
		}else if(g_iDBStatus == 1)// ReConnect every 60 sec
		{
			Database.Connect(EWM_Eban_ConnectCallBack, EW_EBAN_ENTWATCH_SECTION);
		}
	}
	
	return Plugin_Continue;
}

stock void EWM_Eban_OnMapStart()
{
	EWM_Eban_CleanData_All();
}

stock void EWM_Eban_OnClientPutInServer(int iClient)
{
	EWM_Eban_CleanData_Client(iClient);
	EWM_Eban_Update_Client(iClient);
}

stock void EWM_Eban_OnClientDisconnect(int iClient)
{
	EWM_Eban_CleanData_Client(iClient);
}

void EWM_Eban_CleanData_Client(int iClient)
{
	g_EbanClients[iClient].Banned = false;
	FormatEx(g_EbanClients[iClient].Admin_Name, 32, "");
	FormatEx(g_EbanClients[iClient].Admin_SteamID, 64, "");
	g_EbanClients[iClient].Duration = 0;
	g_EbanClients[iClient].TimeStamp_Issued = 0;
	FormatEx(g_EbanClients[iClient].Reason, 64, "");
}

void EWM_Eban_CleanData_All()
{
	for(int i=1; i<=MaxClients; i++)
	{
		EWM_Eban_CleanData_Client(i);
		if(IsClientInGame(i)) EWM_Eban_Update_Client(i);
	}
}

//-------------------------------------------------------
// Purpose: Ban a client
//-------------------------------------------------------
public Action EWM_Eban_Command_Restrict(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (GetCmdArgs() < 1)
		{
			CReplyToCommand(iClient, "%s%t %s%t: sm_eban <target> [<duration>] [<reason>]", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Usage");
			return Plugin_Handled;
		}
		char sTarget_argument[64];
		GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

		int iTarget = -1;
		if((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;
		
		int iDuration = -1;
		char sReason[64];
		if(GetCmdArgs() == 1)
		{
			iDuration = GetConVarInt(g_hCvar_Default_BanTime);
			if(GetConVarBool(g_hCvar_Use_Reason_Menu))
			{
				EWM_Eban_Menu_EBanReason(iClient, iTarget, iDuration);
				return Plugin_Handled;
			}else
			{
				GetConVarString(g_hCvar_Default_BanReason, sReason, sizeof(sReason));
			}
		}else if(GetCmdArgs() == 2)
		{
			GetCmdArg(2, sTarget_argument, sizeof(sTarget_argument));
			iDuration = StringToInt(sTarget_argument);
			if(GetConVarBool(g_hCvar_Use_Reason_Menu))
			{
				EWM_Eban_Menu_EBanReason(iClient, iTarget, iDuration);
				return Plugin_Handled;
			}else
			{
				GetConVarString(g_hCvar_Default_BanReason, sReason, sizeof(sReason));
			}
		}else
		{
			GetCmdArg(2, sTarget_argument, sizeof(sTarget_argument));
			iDuration = StringToInt(sTarget_argument);
			GetCmdArg(3, sTarget_argument, sizeof(sTarget_argument));
			
			FormatEx(sReason, sizeof(sReason), "%s", sTarget_argument);
		}
		EWM_Eban_BanClient(iTarget, iClient, iDuration, sReason);
	}
	return Plugin_Handled;
}

//-------------------------------------------------------
// Purpose: Unban a client
//-------------------------------------------------------
public Action EWM_Eban_Command_Unrestrict(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (GetCmdArgs() < 1)
		{
			CReplyToCommand(iClient, "%s%t %s%t: sm_eunban <target> [<reason>]", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Usage");
			return Plugin_Handled;
		}
		char sTarget_argument[64];
		GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

		int iTarget = -1;
		if((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;
		
		FormatEx(sTarget_argument, sizeof(sTarget_argument), "No Reason");
		if(GetCmdArgs() > 1) GetCmdArg(2, sTarget_argument, sizeof(sTarget_argument));
		EWM_Eban_UnBanClient(iTarget, iClient, sTarget_argument);
	}
	return Plugin_Handled;
}

//-------------------------------------------------------
// Purpose: Lists the clients that are currently on the server and banned
//-------------------------------------------------------
public Action EWM_Eban_Command_EBanlist(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		CReplyToCommand(iClient, "%s%t %s%t:", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Currently Eban");
		bool bFirst = true;
		for(int i=1; i<MaxClients+1; i++)
		{
			if(!IsClientInGame(i)) continue;
			
			if(g_EbanClients[i].Banned)
			{
				bFirst = false;
				char sBuff[256];
				if(g_EbanClients[i].Duration==-1)
					FormatEx(sBuff, sizeof(sBuff), "%T: %T", "Duration", iClient, "Temporary", iClient);
				else if(g_EbanClients[i].Duration==0)
					FormatEx(sBuff, sizeof(sBuff), "%T: %T", "Duration", iClient, "Permanently", iClient);
				else 
				{
					char sIssuedBuf[64];
					FormatTime(sIssuedBuf, sizeof(sIssuedBuf), NULL_STRING, g_EbanClients[i].TimeStamp_Issued);
					FormatEx(sBuff, sizeof(sBuff), "%T: %i %T: %s", "Duration", iClient, g_EbanClients[i].Duration, "Issued", iClient, sIssuedBuf);
				}
				CReplyToCommand(iClient, "%s#%i \t%N \t%t: %s(%s) \t%s \t%t: %s", g_SchemeConfig.Color_Warning, GetClientUserId(i), i, "Admin", g_EbanClients[i].Admin_Name,  g_EbanClients[i].Admin_SteamID, sBuff, "Reason", g_EbanClients[i].Reason);
			}
		}
		if(bFirst) CReplyToCommand(iClient, "%s%t.", g_SchemeConfig.Color_Warning, "No EBans");
	}
	return Plugin_Handled;
}

public Action EWM_Eban_Command_Status(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (iArgs != 0 && CheckCommandAccess(iClient, "", ADMFLAG_BAN, true))
		{
			char sTarget_argument[64];
			GetCmdArg(1, sTarget_argument, sizeof(sTarget_argument));

			int iTarget = -1;
			if((iTarget = FindTarget(iClient, sTarget_argument, true)) == -1) return Plugin_Handled;
			
			if(g_EbanClients[iTarget].Banned)
			{
				char sBuff[256];
				if(g_EbanClients[iTarget].Duration==-1)
					FormatEx(sBuff, sizeof(sBuff), "%T: %T", "Duration", iClient, "Temporary", iClient);
				else if(g_EbanClients[iTarget].Duration==0)
					FormatEx(sBuff, sizeof(sBuff), "%T: %T", "Duration", iClient, "Permanently", iClient);
				else 
				{
					char sIssuedBuf[64];
					FormatTime(sIssuedBuf, sizeof(sIssuedBuf), NULL_STRING, g_EbanClients[iTarget].TimeStamp_Issued);
					FormatEx(sBuff, sizeof(sBuff), "%T: %i %T: %s", "Duration", iClient, g_EbanClients[iTarget].Duration, "Issued", iClient, sIssuedBuf);
				}
				CReplyToCommand(iClient, "%s%t %s%t %s%N %s%t.", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player", g_SchemeConfig.Color_Name, iTarget, g_SchemeConfig.Color_Warning, "Has a Restrict");
				CReplyToCommand(iClient, "%s%t %s%t: %s%s%s(%s%s%s) %s %t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Admin", g_SchemeConfig.Color_Name, g_EbanClients[iTarget].Admin_Name, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, g_EbanClients[iTarget].Admin_SteamID, g_SchemeConfig.Color_Warning, sBuff, "Reason", g_EbanClients[iTarget].Reason);
			}else CReplyToCommand(iClient, "%s%t %s%t %s%N %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player", g_SchemeConfig.Color_Name, iTarget, g_SchemeConfig.Color_Warning, "Is not restricted");
			return Plugin_Handled;
		}
		
		if(g_EbanClients[iClient].Banned)
		{
			char sBuff[256];
			if(g_EbanClients[iClient].Duration==-1)
				FormatEx(sBuff, sizeof(sBuff), "%T: %T", "Duration", iClient, "Temporary", iClient);
			else if(g_EbanClients[iClient].Duration==0)
				FormatEx(sBuff, sizeof(sBuff), "%T: %T", "Duration", iClient, "Permanently", iClient);
			else 
			{
				char sIssuedBuf[64];
				FormatTime(sIssuedBuf, sizeof(sIssuedBuf), NULL_STRING, g_EbanClients[iClient].TimeStamp_Issued);
				FormatEx(sBuff, sizeof(sBuff), "%T: %i %T: %s", "Duration", iClient, g_EbanClients[iClient].Duration, "Issued", iClient, sIssuedBuf);
			}
			CReplyToCommand(iClient, "%s%t %s%t%s.", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Disabled, "Status restricted", g_SchemeConfig.Color_Warning);
			CReplyToCommand(iClient, "%s%t %s%t: %s%s%s(%s%s%s) %s %t: %s", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Admin", g_SchemeConfig.Color_Name, g_EbanClients[iClient].Admin_Name, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_SteamID, g_EbanClients[iClient].Admin_SteamID, g_SchemeConfig.Color_Warning, sBuff, "Reason", g_EbanClients[iClient].Reason);
		}else CReplyToCommand(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Enabled, "Status unrestricted");
	}
	return Plugin_Handled;
}

//Menus
void EWM_Eban_Menu_EBanReason(int iClient, int iTarget, int iDuration)
{
	Menu hMenu = CreateMenu(EWM_Eban_Menu_EBanReason_Handler);
	char sMenuTranslate[128], sMenuTemp[64], sIndexTemp[96];
	if(iDuration == -1) FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N [%T]", "EW_Tag", iClient, "EBan Reason for", iClient, iTarget, "Temporary", iClient);
	else if(iDuration == 0) FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N [%T]", "EW_Tag", iClient, "EBan Reason for", iClient, iTarget, "Permanently", iClient);
		else FormatEx(sMenuTranslate, sizeof(sMenuTranslate), "%T %T %N [%i %T]", "EW_Tag", iClient, "EBan Reason for", iClient, iTarget, iDuration, "Minutes", iClient);
	hMenu.SetTitle(sMenuTranslate);
	
	int iUserID = GetClientUserId(iTarget);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Item misuse");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Item misuse", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Trolling on purpose");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Trolling on purpose", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Throwing item away");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Throwing item away", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Not using an item");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not using an item", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Trimming team");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Trimming team", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Not listening to leader");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Not listening to leader", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Spamming an item");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Spamming an item", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	FormatEx(sIndexTemp, sizeof(sIndexTemp), "%i/%i/%s", iDuration, iUserID, "Other");
	FormatEx(sMenuTemp, sizeof(sMenuTemp), "%T", "Other", iClient);
	hMenu.AddItem(sIndexTemp, sMenuTemp);
	
	hMenu.Display(iClient, MENU_TIME_FOREVER);
}

public int EWM_Eban_Menu_EBanReason_Handler(Menu hMenu, MenuAction hAction, int iClient, int iParam2)
{
	switch(hAction)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Select:
		{
			char sSelected[96], Explode_sParam[3][96], sReason[32];
			hMenu.GetItem(iParam2, sSelected, sizeof(sSelected));
			ExplodeString(sSelected, "/", Explode_sParam, 3, 96);
			int iDuration = StringToInt(Explode_sParam[0]);
			int iTarget = GetClientOfUserId(StringToInt(Explode_sParam[1]));
			FormatEx(sReason, sizeof(sReason), "%s", Explode_sParam[2]);
			if(IsValidClient(iTarget))
				EWM_Eban_BanClient(iTarget, iClient, iDuration, sReason);
			else
				CPrintToChat(iClient, "%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Player is not valid anymore");
		}
	}
}
