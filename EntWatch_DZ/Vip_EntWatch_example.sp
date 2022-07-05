#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <EntWatch>
#include <vip_core>

public Plugin myinfo = 
{
	name = "VIP EntWatch Privileges", 
	author = "DarkerZ[RUS]", 
	description = "", 
	version = "1.0", 
	url = ""
}

static const char g_sFeature[][] = {"EntWatchWeapon", "EntWatchPlayer"};

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature[0], BOOL, _, OnToggleItemWeapon);
	VIP_RegisterFeature(g_sFeature[1], BOOL, _, OnToggleItemPlayer);
}

public void OnPluginStart()
{
	LoadTranslations("vip_modules.phrases");
	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}

public Action OnToggleItemWeapon(int iClient, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &NewStatus)
{
	if(IsValidClient(iClient))
	{
		if(NewStatus == ENABLED) EntWatch_SetHLWeaponOne(iClient);
		else EntWatch_RemoveHLWeaponOne(iClient);
	}
	return Plugin_Continue;
}

public Action OnToggleItemPlayer(int iClient, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &NewStatus)
{
	if(IsValidClient(iClient))
	{
		if(NewStatus == ENABLED) EntWatch_SetHLPlayerOne(iClient);
		else EntWatch_RemoveHLPlayerOne(iClient);
	}
	return Plugin_Continue;
}

public void VIP_OnVIPClientLoaded(int iClient)
{
	if(IsValidClient(iClient) && VIP_GetClientFeatureStatus(iClient, g_sFeature[0]) != NO_ACCESS) EntWatch_SetHLWeaponOne(iClient);
	if(IsValidClient(iClient) && VIP_GetClientFeatureStatus(iClient, g_sFeature[1]) != NO_ACCESS) EntWatch_SetHLPlayerOne(iClient);
}

public void EntWatch_OnHLWeaponReady()
{
	int iCount = 0, iClients[MAXPLAYERS+1] = {0,...};
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature[0])) iClients[iCount++] = i;
	}
	EntWatch_SetHLWeapon(iCount, iClients);
}

public void EntWatch_OnHLPlayerReady()
{
	int iCount = 0, iClients[MAXPLAYERS+1] = {0,...};
	for(int i = 1; i < MaxClients; i++)
	{
		if(IsValidClient(i) && VIP_IsClientVIP(i) && VIP_IsClientFeatureUse(i, g_sFeature[1])) iClients[iCount++] = i;
	}
	EntWatch_SetHLPlayer(iCount, iClients);
}

stock bool IsValidClient(int iClient) 
{ 
	if (iClient > 0 && iClient <= MaxClients && IsValidEdict(iClient) && IsClientInGame(iClient)) return true; 
	return false; 
}