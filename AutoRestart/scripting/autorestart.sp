#pragma semicolon 1

#include <csgocolors_fix>

ConVar g_hCvar_Enabled;
ConVar g_hCvar_Time;
ConVar g_hCvar_Wait;

bool 	g_bEnabled = true;
int 	g_iTime = 500;
int		g_iWait = 5;

int 	g_iTimeLeft = -1;

int 	g_iLastCheck = 0;

public Plugin:myinfo = {
	name = "AutoRestart",
	author = "DarkerZ [RUS]",
	description = "Restarts servers once a day.",
	version = "1.0",
	url = "dark-skill.ru",
}

public OnPluginStart() {
	LoadTranslations("autorestart.phrases");
	RegAdminCmd("sm_forcerestart", Command_FRestart, ADMFLAG_ROOT);
	
	g_hCvar_Enabled = CreateConVar("sm_autorestart", "1", "Enable AutoRestart", _, true, 0.0, true, 1.0);
	g_hCvar_Time = CreateConVar("sm_autorestart_time", "0500", "Time to restart server at", _, true, 0.0, true, 2359.0);
	g_hCvar_Wait = CreateConVar("sm_autorestart_wait", "5", "Wait to restart server at", _, true, 0.0, true, 30.0);
	
	g_bEnabled = GetConVarBool(g_hCvar_Enabled);
	g_iTime = GetConVarInt(g_hCvar_Time);
	g_iWait = GetConVarInt(g_hCvar_Wait);
	
	char time[8];
	FormatTime(time, sizeof(time), "%H%M");
	g_iLastCheck = StringToInt(time);
	
	HookConVarChange(g_hCvar_Enabled, Cvar_Enabled);
	HookConVarChange(g_hCvar_Time, Cvar_Time);
	HookConVarChange(g_hCvar_Wait, Cvar_Wait);

	CreateTimer(300.0, CheckRestart, 0, TIMER_REPEAT);
}

public void Cvar_Enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = GetConVarBool(convar);
}

public void Cvar_Time(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iTime = GetConVarInt(convar);
}

public void Cvar_Wait(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iWait = GetConVarInt(convar);
}

public Action CheckRestart(Handle:timer, any:ignore)
{
	if(!g_bEnabled)
	{
		return;
	}
	
	if(g_iTimeLeft>-1)
	{
		return;
	}
	
	char time[8];
	FormatTime(time, sizeof(time), "%H%M");
	int current_time = StringToInt(time);

	if(current_time >= g_iLastCheck)
	{
		if((current_time >= g_iTime)&&(g_iLastCheck <= g_iTime))
		{
			//restart
			Restart_Time(g_iWait);
		}
	} else 
	{
		if((current_time < g_iTime)&&(g_iLastCheck <= g_iTime))
		{
			//restart
			Restart_Time(g_iWait);
		} else if((current_time >= g_iTime)&&(g_iLastCheck > g_iTime))
		{
			//restart
			Restart_Time(g_iWait);
		}
	}
	
	g_iLastCheck = current_time;
}

public void Restart_Time(int wTime)
{
	if(wTime<0)
	{
		return;
	} else if(wTime==0)
	{
		g_iTimeLeft=10;
		CreateTimer(1.0, Timer_Restart, _, TIMER_REPEAT);
	} else if(wTime>0)
	{
		g_iTimeLeft=wTime*60;
		CreateTimer(1.0, Timer_Restart, _, TIMER_REPEAT);
	}
}

public Action Timer_Restart(Handle:timer, any:ignore)
{
	if (g_iTimeLeft >= 0)
	{
		Restart_Announce();
		g_iTimeLeft--;
		return Plugin_Continue;
	}
	g_iTimeLeft=-1;
	LogMessage( "Restarting..." );
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			ClientCommand(client, "retry");
		}
	}
	ServerCommand( "_restart" );
	return Plugin_Stop;
}

public void Restart_Announce()
{
	if(g_iTimeLeft<=60)
	{
		Restart_Announce_Messages(g_iTimeLeft, false);
	} else
	{
		int iSeconds = (g_iTimeLeft % 60);
		if(iSeconds==0)
		{
			int iMinutes = ((g_iTimeLeft / 60) % 60);
			Restart_Announce_Messages(iMinutes, true);
		}
	}
}

public void Restart_Announce_Messages(int wTime, bool wMin)
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			char message[255];
			if(wMin)
			{
				Format(message, 255, "%T %T", "Auto Restart Tag", client, "Auto Restart Wait Min", client, wTime);
				CPrintToChat(client, "%t %t", "Auto Restart Tag Color", "Auto Restart Wait Min Color", wTime);
			} else 
			{
				Format(message, 255, "%T %T", "Auto Restart Tag", client, "Auto Restart Wait Sec", client, wTime);
				CPrintToChat(client, "%t %t", "Auto Restart Tag Color", "Auto Restart Wait Sec Color", wTime);
			}
			ReplyToCommand(client, message);
			Handle hHudText = CreateHudSynchronizer();
			if(wMin)
			{
				SetHudTextParams(-1.0, 0.15, 3.0, 100, 100, 255, 255, 1, 1.0, 0.1, 0.1);
			} else 
			{
				SetHudTextParams(-1.0, 0.15, 1.0, 100, 100, 255, 255, 1, 1.0, 0.1, 0.1);
			}
			ShowSyncHudText(client, hHudText, message);
			CloseHandle(hHudText);
		}
	}
}

public Action Command_FRestart(int iClient, int iArgs)
{
	if (GetCmdArgs() > 1)
	{
		ReplyToCommand(iClient, "[AutoRestart] Usage: sm_forcerestart [<time>]");
		return Plugin_Handled;
	}
	if (GetCmdArgs() < 1)
	{
		CPrintToChatAll("%t %t", "Auto Restart Tag Color", "Auto Restart Admin Start", iClient);
		LogAction(iClient, -1, "[AutoRestart] Admin %N Launched a Restart Server", iClient);
		Restart_Time(0);
		return Plugin_Handled;
	}
	if (GetCmdArgs() == 1)
	{
		char sArgs[16];
		GetCmdArg(1, sArgs, sizeof(sArgs));
		int iWait;
		if (!StringToIntEx(sArgs, iWait))
		{
			ReplyToCommand(iClient, "[SM] Invalid value");
			return Plugin_Handled;
		}
		CPrintToChatAll("%t %t", "Auto Restart Tag Color", "Auto Restart Admin Start", iClient);
		LogAction(iClient, -1, "[AutoRestart] Admin %N Launched a Restart Server", iClient);
		Restart_Time(iWait);
		return Plugin_Handled;
	}
	return Plugin_Handled;
}