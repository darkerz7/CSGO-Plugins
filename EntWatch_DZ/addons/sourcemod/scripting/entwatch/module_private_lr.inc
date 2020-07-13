#define EW_MODULE_PRIVATE_LR

#include <lvl_ranks>

ConVar g_hCvar_LR_Rank;
int g_iLR_Rank = 2;
int g_iRank[MAXPLAYERS+1];
bool g_bDontSpamTouch[MAXPLAYERS + 1] = {false,...};

stock void EWM_Private_LR_OnPluginStart()
{
	g_hCvar_LR_Rank       = CreateConVar("entwatch_lr_rank", "2", "Change Rank for pickup item", _, true, 0.0, true, 128.0);
	HookConVarChange(g_hCvar_LR_Rank, Cvar_LR_Rank_Changed);
	
	LoadTranslations("EntWatch_DZ_LR.phrases");
	
	if(LR_IsLoaded()) EWM_Private_LR_OnCoreIsReady();
}

void Cvar_LR_Rank_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iLR_Rank = GetConVarInt(convar);
}

void EWM_Private_LR_OnCoreIsReady()
{
	LR_Hook(LR_OnPlayerLoaded, EWM_Private_LR_OnLoadPlayer);
	LR_Hook(LR_OnLevelChangedPost, EWM_Private_LR_OnLevelChanged);
}

void EWM_Private_LR_OnLoadPlayer(int iClient, int iAccountID)
{
	g_iRank[iClient] = LR_GetClientInfo(iClient, ST_RANK);
}

void EWM_Private_LR_OnLevelChanged(int iClient, int iNewLevel, int iOldLevel)
{
	g_iRank[iClient] = iNewLevel;
}

Action EWM_Private_LR_DontSpamTimer_End(Handle timer, int iClient)
{
	g_bDontSpamTouch[iClient] = false;
}

bool EWM_Private_LR_OnWeaponCanUse(int iClient)
{
	if (g_iRank[iClient]<g_iLR_Rank)
	{
		if(g_bDontSpamTouch[iClient]==false)
		{
			g_bDontSpamTouch[iClient]=true;
			CreateTimer(5.0, EWM_Private_LR_DontSpamTimer_End, iClient);
			CPrintToChat(iClient,"%s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "LR Low Rank");
		}
		return true;
	}
	return false;
}