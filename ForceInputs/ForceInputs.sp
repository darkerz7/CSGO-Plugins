//====================================================================================================
//
// Name: ForceInput
// Author: zaCade + BotoX
// Description: Allows admins to force inputs on entities. (ent_fire)
//
//====================================================================================================
#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name 			= "ForceInput",
	author 			= "zaCade + BotoX + DarkerZ[RUS]",
	description 	= "Allows admins to force inputs on entities. (ent_fire)",
	version 		= "2.1.1a",
	url 			= ""
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_forceinput", Command_ForceInput, ADMFLAG_ROOT);
	RegAdminCmd("sm_forceinputplayer", Command_ForceInputPlayer, ADMFLAG_ROOT);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_ForceInputPlayer(int client, int args)
{
	if(GetCmdArgs() < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forceinputplayer <target> <input> [parameter]");
		return Plugin_Handled;
	}

	char sArguments[3][256];
	GetCmdArg(1, sArguments[0], sizeof(sArguments[]));
	GetCmdArg(2, sArguments[1], sizeof(sArguments[]));
	GetCmdArg(3, sArguments[2], sizeof(sArguments[]));

	char sTargetName[MAX_TARGET_LENGTH];
	int aTargetList[MAXPLAYERS];
	int TargetCount;
	bool TnIsMl;

	if((TargetCount = ProcessTargetString(
			sArguments[0],
			client,
			aTargetList,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_IMMUNITY,
			sTargetName,
			sizeof(sTargetName),
			TnIsMl)) <= 0)
	{
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}

	for(int i = 0; i < TargetCount; i++)
	{
		if(!IsValidEntity(aTargetList[i]))
			continue;

		if(sArguments[2][0])
			SetVariantString(sArguments[2]);

		AcceptEntityInput(aTargetList[i], sArguments[1], aTargetList[i], aTargetList[i]);
		ReplyToCommand(client, "[SM] Input successful.");
		LogAction(client, -1, "\"%L\" used ForceInputPlayer on \"%L\": \"%s %s\"", client, aTargetList[i], sArguments[1], sArguments[2]);
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_ForceInput(int client, int args)
{
	if(GetCmdArgs() < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_forceinput <classname/targetname> <input> [parameter]");
		return Plugin_Handled;
	}

	char sArguments[3][256];
	GetCmdArg(1, sArguments[0], sizeof(sArguments[]));
	GetCmdArg(2, sArguments[1], sizeof(sArguments[]));
	GetCmdArg(3, sArguments[2], sizeof(sArguments[]));

	if(StrEqual(sArguments[0], "!self"))
	{
		if(sArguments[2][0])
			SetVariantString(sArguments[2]);

		AcceptEntityInput(client, sArguments[1], client, client);
		ReplyToCommand(client, "[SM] Input successful.");
		LogAction(client, -1, "\"%L\" used ForceInput on himself: \"%s %s\"", client, sArguments[1], sArguments[2]);
	}
	else if(StrEqual(sArguments[0], "!target"))
	{
		float fPosition[3];
		float fAngles[3];
		GetClientEyePosition(client, fPosition);
		GetClientEyeAngles(client, fAngles);

		Handle hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);

		if(TR_DidHit(hTrace))
		{
			int entity = TR_GetEntityIndex(hTrace);

			if(entity <= 1 || !IsValidEntity(entity))
			{
				CloseHandle(hTrace);
				return Plugin_Handled;
			}

			if(sArguments[2][0])
				SetVariantString(sArguments[2]);

			AcceptEntityInput(entity, sArguments[1], client, client);
			ReplyToCommand(client, "[SM] Input successful.");

			char sClassname[64];
			char sTargetname[64];
			GetEntPropString(entity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
			GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
			LogAction(client, -1, "\"%L\" used ForceInput on Entity \"%d\"  - \"%s\" - \"%s\": \"%s %s\"", client, entity, sClassname, sTargetname, sArguments[1], sArguments[2]);
		}
		CloseHandle(hTrace);
	}
	else if(sArguments[0][0] == '#') // HammerID
	{
		int HammerID = StringToInt(sArguments[0][1]);

		int entity = INVALID_ENT_REFERENCE;
		while((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntProp(entity, Prop_Data, "m_iHammerID") == HammerID)
			{
				if(sArguments[2][0])
					SetVariantString(sArguments[2]);

				AcceptEntityInput(entity, sArguments[1], client, client);
				ReplyToCommand(client, "[SM] Input successful.");

				char sClassname[64];
				char sTargetname[64];
				GetEntPropString(entity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
				GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
				LogAction(client, -1, "\"%L\" used ForceInput on Entity \"%d\"  - \"%s\" - \"%s\": \"%s %s\"", client, entity, sClassname, sTargetname, sArguments[1], sArguments[2]);
			}
		}
	}
	else
	{
		int entity = INVALID_ENT_REFERENCE;
		while((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
		{
			char sClassname[64],sClassname2[64];
			char sTargetname[64],sTargetname2[64];
			char sBuffer[64];
			GetEntPropString(entity, Prop_Data, "m_iClassname", sClassname, sizeof(sClassname));
			GetEntPropString(entity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

			int iWildcard = 0;
			if((iWildcard = SplitString(sArguments[0],"*",sBuffer,64))!=-1)
			{
				strcopy(sClassname2, iWildcard, sClassname);
				strcopy(sTargetname2, iWildcard, sTargetname);
			} else 
			{
				FormatEx(sBuffer, 64, "%s", sArguments[0]);
				FormatEx(sClassname2, 64, "%s", sClassname);
				FormatEx(sTargetname2, 64, "%s", sTargetname);
			}
			if(StrEqual(sClassname2, sBuffer, false)
				|| StrEqual(sTargetname2, sBuffer, false))
			{
				if(sArguments[2][0])
					SetVariantString(sArguments[2]);

				AcceptEntityInput(entity, sArguments[1], client, client);
				ReplyToCommand(client, "[SM] Input successful.");
				LogAction(client, -1, "\"%L\" used ForceInput on Entity \"%d\"  - \"%s\" - \"%s\": \"%s %s\"", client, entity, sClassname, sTargetname, sArguments[1], sArguments[2]);
			}
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public bool TraceRayFilter(int entity, int mask, any client)
{
	if(entity == client)
		return false;

	return true;
}