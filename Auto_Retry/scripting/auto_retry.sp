#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <csgocolors_fix>

Database g_DB = null;
int MainTimer[MAXPLAYERS+1] = 0;
int AutoRetryTimer[MAXPLAYERS+1] = -1;

bool g_bReady = false;

ArrayList CurrentMapPlayersSteam;

public Plugin myinfo =
{
	name = "AutoRetry",
	author = "DarkerZ[RUS]",
	description = "AutoRetry After Download Map",
	version = "1.5",
	url = "dark-skill.ru"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_retryclear", SMRETRYCLEAR);
	LoadTranslations("autoretry.phrases");
	
	CurrentMapPlayersSteam = new ArrayList(ByteCountToCells(32));
	Database.Connect(ConnectCallBack, "AutoRetryDB");
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
}

public void SQL_Callback_CheckError(Database hDatabase, DBResultSet results, const char[] szError, any data)
{
	if(szError[0]) LogError("Database Callback Error: %s", szError);
}

public void OnMapStart()
{
	g_bReady = false;
	CurrentMapPlayersSteam.Clear();
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	char query[255];
	FormatEx(query, sizeof(query), "SELECT `steamid` FROM AR_UserMaps WHERE mapname='%s'", mapname); 
	SQL_TQuery(g_DB, SQLT_Callback_CurrentMapResult, query, _, DBPrio_High);
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
	if(g_bReady && IsValidClient(iClient))
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
	if(g_bReady && IsValidClient(client))
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

stock bool IsValidClient(int iClient) 
{ 
	if (iClient > 0 && iClient <= MaxClients && IsValidEdict(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient) && IsClientConnected(iClient)) return true; 
	return false; 
}