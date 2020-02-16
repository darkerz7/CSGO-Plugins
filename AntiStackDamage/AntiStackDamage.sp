#pragma semicolon 1
#include <sdkhooks>

bool g_IgnoreDamage[MAXPLAYERS+1] = false;

public Plugin:myinfo =
{
	name = "[ZR] Anti Stack Damage",
	author = "DarkerZ[RUS]",
	description = "CS:GO Fix trigger_hurt that has Parent",
	version = "1.0",
	url = "dark-skill.ru"
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_IgnoreDamage[client] = false;
}

public Action:OnTakeDamage(iClient, &iAttacker, &Inflictor, &Float:Damage, &Damagetype)
{
	if(GetClientTeam(iClient)==3)//Check CTs
	{
		char c_DamageEntity[32];
		GetEdictClassname(iAttacker, c_DamageEntity, sizeof(c_DamageEntity));
		if(StrEqual(c_DamageEntity, "trigger_hurt")) //Who Damage
		{
			if(Damage<500.0)//Check damage
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

public Action:Timer_Ignore_Damage(Handle:timer, any:iClient)
{
	g_IgnoreDamage[iClient] = false;
	KillTimer(timer);
	return Plugin_Stop;
}