#pragma semicolon 1

#include <sourcemod>
#include <csgocolors_fix>

Database g_DB = null;
int MainTimer[MAXPLAYERS+1] = 0;
int AutoRetryTimer[MAXPLAYERS+1] = -1;

public Plugin:myinfo =
{
	name = "AutoRetry",
	author = "DarkerZ[RUS]",
	description = "AutoRetry After Download Map",
	version = "1.1",
	url = "dark-skill.ru"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_retryclear", SMRETRYCLEAR);
	
	LoadTranslations("autoretry.phrases");
	
	char error[256];
	g_DB = SQLite_UseDatabase("AutoRetryDB", error, 256);
	if (g_DB == null)
    {
		LogError(error);
		SetFailState("Error SQL connection");
		return;
	}
	
	SQL_LockDatabase(g_DB);
	SQL_TQuery(g_DB, SQL_DefCallback, "CREATE TABLE IF NOT EXISTS `AR_UserMaps` (\
		`steamid` varchar(32) NOT NULL, \
		`mapname` varchar(64) NOT NULL, \
		PRIMARY KEY (`steamid`,`mapname`))", 0);
	SQL_UnlockDatabase(g_DB);
	
	g_DB.SetCharset("utf8");
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_To_Retry, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	/* Handle late load */
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientInGame(i) && IsClientAuthorized(i))
				OnClientPostAdminCheck(i);
		}
	}
}

public SQL_DefCallback(Handle owner, Handle hndl, const String:error[], any data)
{
    if(hndl == INVALID_HANDLE) LogError(error);
}

public bool OnClientConnect(client, String:rejectmsg[], maxlen)
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

public OnClientPostAdminCheck(client)
{
	ReplyToCommand(client, "%T %T", "Auto Retry Tag", client,"Auto Retry Connected Time", client, GetTime()-MainTimer[client]);
	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	char query[255];  
	Format(query, sizeof(query), "SELECT * FROM AR_UserMaps WHERE steamid='%s' AND mapname='%s'", steamid, mapname);  
	Handle hquery = SQL_Query(g_DB, query);
	if (hquery == INVALID_HANDLE)
	{
		AutoRetryTimer[client]=-1;
		return;
	}
	if (SQL_FetchRow(hquery))
	{
		AutoRetryTimer[client]=-1;
		return;
	}
	Format(query, sizeof(query), "INSERT INTO AR_UserMaps(steamid, mapname) VALUES('%s', '%s')", steamid, mapname);
	SQL_Query(g_DB, query);
	AutoRetryTimer[client]=5;
}

public Action Timer_To_Retry(Handle hTimer, any data)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && (AutoRetryTimer[client] >= 0))
		{
			if(AutoRetryTimer[client]>0)
			{
				char message[255]; 
				Format(message, 255, "%T %T", "Auto Retry Tag", client, "Auto Retry New Map", client, AutoRetryTimer[client]);
				ReplyToCommand(client, message);
				CPrintToChat(client, "%t %t", "Auto Retry Tag Color", "Auto Retry New Map Color",AutoRetryTimer[client]);
				Handle hHudText = CreateHudSynchronizer();
				SetHudTextParams(-1.0, 0.15, 1.0, 255, 10, 10, 255, 1, 1.0, 0.1, 0.1);
				ShowSyncHudText(client, hHudText, message);
				CloseHandle(hHudText);
				AutoRetryTimer[client]--;
			} else if(AutoRetryTimer[client]==0)
			{
				AutoRetryTimer[client]=-1;
				ClientCommand(client, "retry");
			}
		}
	}
}

public Action SMRETRYCLEAR(client, args)
{
	char query[255];
	char steamid[32];
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof(steamid));
	Format(query, sizeof(query), "DELETE FROM AR_UserMaps WHERE steamid='%s'", steamid);
	SQL_Query(g_DB, query);
	CPrintToChat(client, "%t %t", "Auto Retry Tag Color", "Auto Retry Clear DB");
	return Plugin_Handled;
}