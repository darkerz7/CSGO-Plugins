#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <csgocolors_fix>

Database g_DB = null;
int MainTimer[MAXPLAYERS+1] = 0;
int AutoRetryTimer[MAXPLAYERS+1] = -1;

bool g_bReady = false;
bool g_bSuccessSetDB = false;
bool g_bValidMaplist = false;
bool g_bIgnoreMap = false;

ConVar	g_hCvar_MapList,
		g_hCvar_Mode,
		g_hCvar_AutoDetect;

ArrayList CurrentMapPlayersSteam;
ArrayList AutoRetryMapList;

public Plugin myinfo =
{
	name = "AutoRetry",
	author = "DarkerZ[RUS]",
	description = "AutoRetry After Download Map",
	version = "1.7",
	url = "dark-skill.ru"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_retryclear", SMRETRYCLEAR);
	LoadTranslations("autoretry.phrases");
	
	g_hCvar_MapList		= CreateConVar("autoretry_maplist", "0", "Enable/Disable using maplist.", _, true, 0.0, true, 1.0);
	g_hCvar_Mode		= CreateConVar("autoretry_mode", "0", "Mode for maplist. 0 - AutoRetry Only map in list. 1 - Everyone else", _, true, 0.0, true, 1.0);
	g_hCvar_AutoDetect	= CreateConVar("autoretry_autodetect", "0", "Autodetect map with particles. You need to disable the maplist", _, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_autoretry_reloadmaplist", Reload_Maplist, ADMFLAG_RCON);
	
	CurrentMapPlayersSteam = new ArrayList(ByteCountToCells(32));
	AutoRetryMapList = new ArrayList(ByteCountToCells(64));
	AutoExecConfig(true, "AutoRetry");
	AR_UpdateMapList();
	Database.Connect(ConnectCallBack, "AutoRetryDB");
}

public void AR_UpdateMapList()
{
	g_bValidMaplist = false;
	AutoRetryMapList.Clear();
	
	char sPath[PLATFORM_MAX_PATH], sBuffer[64];
	BuildPath(Path_SM, sPath, sizeof(sPath),"configs/autoretry_maplist.ini");
	Handle hFile = OpenFile(sPath,"r");
	if(!FileExists(sPath) || hFile == INVALID_HANDLE)
	{
		LogMessage("[AutoRetry] Can not open the file for reading");
		return;
	}
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, sBuffer, sizeof(sBuffer)))
	{
		TrimString(sBuffer);
		ReplaceString(sBuffer, sizeof(sBuffer), " ", "");
		if(!StrEqual(sBuffer,""))
		{
			char sMapname[64];
			FormatEx(sMapname, sizeof(sMapname), "%s", sBuffer);
			AutoRetryMapList.PushString(sMapname);
		}
	}
	CloseHandle(hFile);
	if(AutoRetryMapList.Length > 0) g_bValidMaplist = true;
}

public void ConnectCallBack(Database hDatabase, const char[] sError, any data)
{
	if (hDatabase == null)
	{
		SetFailState("Database failure: %s", sError);
		return;
	}
	g_DB = hDatabase;
	char sConnectDriverDB[16];
	g_DB.Driver.GetIdentifier(sConnectDriverDB, sizeof(sConnectDriverDB));
	if(strcmp(sConnectDriverDB, "mysql") == 0 || strcmp(sConnectDriverDB, "sqlite") == 0)
	{
		SQL_LockDatabase(g_DB);
		g_DB.Query(SQL_Callback_CheckError,	"CREATE TABLE IF NOT EXISTS `AR_UserMaps` (\
												`steamid` varchar(32) NOT NULL, \
												`mapname` varchar(64) NOT NULL, \
												PRIMARY KEY (`steamid`,`mapname`))", _, DBPrio_High);
		SQL_UnlockDatabase(g_DB);
	} else
	{
		SetFailState("Database failure: Unknown Driver");
		return;
	}
	
	g_DB.SetCharset("utf8");
	
	g_bSuccessSetDB = true;
}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0]) LogError("Database Callback Error: %s", szError);
}

public void OnMapStart()
{
	g_bReady = false;
	g_bIgnoreMap = false;
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if(GetConVarBool(g_hCvar_MapList) && g_bValidMaplist)
	{
		bool bFound = true;
		if(GetConVarBool(g_hCvar_Mode))
		{
			bFound = false;
			char sTestMap[64];
			for(int i = 0; i < AutoRetryMapList.Length; i++)
			{
				AutoRetryMapList.GetString(i, sTestMap, sizeof(sTestMap));
				if(StrEqual(mapname, sTestMap, false))
				{
					bFound = true;
					break;
				}
			}
		} else
		{
			char sTestMap[64];
			for(int i = 0; i < AutoRetryMapList.Length; i++)
			{
				AutoRetryMapList.GetString(i, sTestMap, sizeof(sTestMap));
				if(StrEqual(mapname, sTestMap, false))
				{
					bFound = false;
					break;
				}
			}
		}
		if(bFound)
		{
			g_bIgnoreMap = true;
			g_bReady = true;
			return;
		}
	}else if(GetConVarBool(g_hCvar_AutoDetect))
	{
		char sManifest[PLATFORM_MAX_PATH];
		FormatEx(sManifest, sizeof(sManifest), "maps/%s_particles.txt", mapname);
		if (!FileExists(sManifest, true, NULL_STRING))
		{
			g_bIgnoreMap = true;
			g_bReady = true;
			return;
		}
	}
	if(g_bSuccessSetDB)
	{
		CurrentMapPlayersSteam.Clear();
		char query[255];
		FormatEx(query, sizeof(query), "SELECT `steamid` FROM AR_UserMaps WHERE mapname='%s'", mapname); 
		SQL_TQuery(g_DB, SQLT_Callback_CurrentMapResult, query, _, DBPrio_High);
	}else
	{
		CreateTimer(5.0, Timer_RecconectDB, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RecconectDB(Handle hTimer, any client)
{
	OnMapStart();
	return Plugin_Stop;
}

void SQLT_Callback_CurrentMapResult(Handle hDatabase, Handle hResults, const char[] sError, any data)
{
	if(sError[0])
	{
		LogError("Database Callback Map Result Error: %s", sError);
	}
	else
	{
		while(SQL_FetchRow(hResults))
		{
			char steamid[32];
			SQL_FetchString(hResults, 0, steamid, sizeof(steamid));
			CurrentMapPlayersSteam.PushString(steamid);
		}
		for(int i = 1; i <= MaxClients; i++)
		{
			CheckClient(i);
		}
		g_bReady = true;
	}
}

public bool OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
	AutoRetryTimer[client]=-1;
	MainTimer[client] = GetTime();
	return true;
}

public void OnClientDisconnect(int client)
{
	MainTimer[client]=0;
	AutoRetryTimer[client]=-1;
}

public void OnClientPostAdminCheck(int client)
{
	CheckClient(client);
}

public void CheckClient(int iClient)
{
	if(g_bReady && !g_bIgnoreMap && IsValidClient(iClient))
	{
		ReplyToCommand(iClient, "%T %T", "Auto Retry Tag", iClient,"Auto Retry Connected Time", iClient, GetTime()-MainTimer[iClient]);
		char steamid[32];
		GetClientAuthId(iClient, AuthId_Engine, steamid, sizeof(steamid));
		if (CurrentMapPlayersSteam.FindString(steamid)>-1)
		{
			AutoRetryTimer[iClient]=-1;
		} else
		{
			CurrentMapPlayersSteam.PushString(steamid);
			AutoRetryTimer[iClient]=5;
			CreateTimer(1.0, Timer_To_Retry, iClient, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			char query[255];
			char mapname[64];
			GetCurrentMap(mapname, sizeof(mapname));
			FormatEx(query, sizeof(query), "INSERT INTO AR_UserMaps(steamid, mapname) VALUES('%s', '%s')", steamid, mapname);
			SQL_TQuery(g_DB, SQLT_Callback_InsertData, query, _, DBPrio_Normal);
		}
	}
}

void SQLT_Callback_InsertData(Handle hDatabase, Handle hResults, const char[] sError, any data)
{
	if(sError[0]) LogError("Database Callback DataEdit Error: %s", sError);
}

public Action Timer_To_Retry(Handle hTimer, any client)
{
	if(IsValidClient(client) && (AutoRetryTimer[client] >= 0))
	{
		if(AutoRetryTimer[client]>0)
		{
			char message[255]; 
			FormatEx(message, 255, "%T %T", "Auto Retry Tag", client, "Auto Retry New Map", client, AutoRetryTimer[client]);
			ReplyToCommand(client, message);
			CPrintToChat(client, "%t %t", "Auto Retry Tag Color", "Auto Retry New Map Color",AutoRetryTimer[client]);
			Handle hHudText = CreateHudSynchronizer();
			SetHudTextParams(-1.0, 0.15, 1.0, 255, 10, 10, 255, 1, 1.0, 0.1, 0.1);
			ShowSyncHudText(client, hHudText, message);
			CloseHandle(hHudText);
			AutoRetryTimer[client]--;
			return Plugin_Continue;
		} else if(AutoRetryTimer[client]==0)
		{
			AutoRetryTimer[client]=-1;
			ClientCommand(client, "retry");
		}
	}
	return Plugin_Stop;
}

public Action SMRETRYCLEAR(int client, int args)
{
	if((g_bReady || (g_bIgnoreMap && g_bSuccessSetDB)) && IsValidClient(client))
	{
		char query[255];
		char steamid[32];
		GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
		FormatEx(query, sizeof(query), "DELETE FROM AR_UserMaps WHERE steamid='%s'", steamid);
		SQL_TQuery(g_DB, SQLT_Callback_InsertData, query, _, DBPrio_Normal);
		int index = CurrentMapPlayersSteam.FindString(steamid);
		if(index>-1)
		{
			CurrentMapPlayersSteam.Erase(index);
		}
		CPrintToChat(client, "%t %t", "Auto Retry Tag Color", "Auto Retry Clear DB");
	}
	return Plugin_Handled;
}

public Action Reload_Maplist(int iClient, int iArgs)
{
	AR_UpdateMapList();
	if(IsValidClient(iClient)) CPrintToChat(iClient, "%t %s", "Auto Retry Tag Color", "Reloading maplist...");
	LogAction(iClient, -1, "\"%L\" Reloaded Maplist", iClient);
	return Plugin_Handled;
}

stock bool IsValidClient(int iClient) 
{ 
	if (iClient > 0 && iClient <= MaxClients && IsValidEdict(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && IsClientConnected(iClient)) return true; 
	return false; 
}