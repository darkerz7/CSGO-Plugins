#pragma semicolon 1
#pragma newdecls required
#include <sdkhooks>

bool g_IgnoreDamage[MAXPLAYERS+1] = false;

public Plugin myinfo =
{
	name = "[ZR] Anti Stack Damage",
	author = "DarkerZ[RUS]",
	description = "CS:GO Fix trigger_hurt that has Parent",
	version = "1.1",
	url = "dark-skill.ru"
}

public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
	g_IgnoreDamage[iClient] = false;
}

public void OnClientDisconnect(int iClient)
{
	SDKUnhook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int iClient, int &iAttacker, int &Inflictor, float &iDamage, int &Damagetype)
{
	if(GetClientTeam(iClient)==3)//Check CTs
	{
		char cDamageEntity[32];
		GetEntityClassname(iAttacker, cDamageEntity, sizeof(cDamageEntity));
		if(StrEqual(cDamageEntity, "trigger_hurt")) //Who Damage
		{
			if(iDamage<500.0)//Check damage
			{
				if(g_IgnoreDamage[iClient] == true)
				{
					return Plugin_Handled;
				} else 
				{
					g_IgnoreDamage[iClient] = true;
					CreateTimer(0.5, Timer_Ignore_Damage, iClient);
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action Timer_Ignore_Damage(Handle timer, any iClient)
{
	g_IgnoreDamage[iClient] = false;
	KillTimer(timer);
	return Plugin_Stop;
}