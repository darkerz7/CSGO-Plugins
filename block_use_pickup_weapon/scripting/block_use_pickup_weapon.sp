#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "[ZR]Block Use PickUp Weapon",
	author = "DarkerZ[RUS]",
	description = "Ignore PickUp Weapons with press E",
	version = "1.0",
	url = ""
};

public OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	//SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public Action:OnWeaponCanUse(int client, int weapon)
{
	if(GetClientButtons(client) & IN_USE)
		return Plugin_Handled;
	return Plugin_Continue; 
}

/*public Action:OnWeaponDrop(int client, int weapon)
{
	if(GetClientButtons(client) & IN_USE)
		return Plugin_Stop;
	return Plugin_Continue; 
}*/