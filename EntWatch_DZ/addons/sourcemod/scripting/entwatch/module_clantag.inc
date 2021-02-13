#define EW_MODULE_CLANTAG

#define MAXSIZECLANTAG 16

char g_sClanTag[MAXPLAYERS+1][MAXSIZECLANTAG];

bool g_bNotHasItem[MAXPLAYERS+1] = {false,...};

stock void EWM_Clantag_OnPluginStart()
{
	CreateTimer(1.0, EWM_Clantag_Timer_UpdateClantag, _, TIMER_REPEAT);
	HookEventEx("player_connect_full", Event_PlayerConnectFull);
}

//Get Client ClanTag on Connect
public Action Event_PlayerConnectFull(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	CS_GetClientClanTag(iClient, g_sClanTag[iClient], MAXSIZECLANTAG);
}

//Get Client ClanTag on Change
public void OnClientSettingsChanged(int iClient)
{
	if(IsValidClient(iClient)) CS_GetClientClanTag(iClient, g_sClanTag[iClient], MAXSIZECLANTAG);
}

//Clear stored ClanTag
stock void EWM_Clantag_OnClientDisconnect(int iClient)
{
	FormatEx(g_sClanTag[iClient], MAXSIZECLANTAG, "");
}

stock void EWM_Clantag_Mass_Reset()
{
	for(int i = 1; i <= MaxClients; i++) EWM_Clantag_Reset(i);
}

stock void EWM_Clantag_Reset(int iClient)
{
	if(IsValidClient(iClient))
	{
		g_bNotHasItem[iClient] = true;
		CS_SetClientClanTag(iClient, g_sClanTag[iClient]);
		CS_SetClientContributionScore(iClient, 0);
	}
}

stock void EWM_Clantag_SetScore(int iClient)
{
	g_bNotHasItem[iClient] = false;
	CS_SetClientContributionScore(iClient, 9999);
}

public Action EWM_Clantag_Timer_UpdateClantag(Handle timer, int client)
{
	if (g_bConfigLoaded)
	{
		for(int i = 0; i<g_ItemList.Length; i++)
		{
			class_ItemList ItemTest;
			g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
			if(ItemTest.Hud && ItemTest.OwnerID != INVALID_ENT_REFERENCE && IsValidEdict(ItemTest.WeaponID))
			{
				ItemTest.UpdateTime();
				char sClanName[MAXSIZECLANTAG];
				
				if(ItemTest.CheckDelay() > 0)
				{
					FormatEx(sClanName, MAXSIZECLANTAG, "%s[-%d]:", ItemTest.ShortName, ItemTest.RoundDelay());
				}else
				{
					switch(ItemTest.Mode)
					{
						case 2:
						{
							if (ItemTest.CheckCoolDown() > 0) FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d]:", ItemTest.ShortName, ItemTest.RoundCoolDown());
							else FormatEx(sClanName, MAXSIZECLANTAG, "%s[R]:", ItemTest.ShortName);
						}
						case 3:
						{
							if (ItemTest.Uses < ItemTest.MaxUses) FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d/%d]:", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
							else FormatEx(sClanName, MAXSIZECLANTAG, "%s[E]:", ItemTest.ShortName);
						}
						case 4:
						{
							if (ItemTest.CheckCoolDown() > 0) FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d]:", ItemTest.ShortName, ItemTest.RoundCoolDown());
							else
								if (ItemTest.Uses < ItemTest.MaxUses) FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d/%d]:", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
								else FormatEx(sClanName, MAXSIZECLANTAG, "%s[E]:", ItemTest.ShortName);
						}
						case 5:
						{
							if (ItemTest.CheckCoolDown() > 0) FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d]:", ItemTest.ShortName, ItemTest.RoundCoolDown());
							else FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d/%d]:", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
						}
						case 6, 7:
						{
							if (ItemTest.MathValue > 0) FormatEx(sClanName, MAXSIZECLANTAG, "%s[%d/%d]:", ItemTest.ShortName, ItemTest.MathValue, ItemTest.MathValueMax);
							else FormatEx(sClanName, MAXSIZECLANTAG, "%s[E]:", ItemTest.ShortName);
						}
						default:
						{
							FormatEx(sClanName, MAXSIZECLANTAG, "%s[+]:", ItemTest.ShortName);
						}
					}
				}
				if(IsValidClient(ItemTest.OwnerID) && IsPlayerAlive(ItemTest.OwnerID))
				{
					CS_SetClientClanTag(ItemTest.OwnerID, sClanName);
					if(g_bNotHasItem[ItemTest.OwnerID]) EWM_Clantag_SetScore(ItemTest.OwnerID);
				}
			}
		}
	}
	return Plugin_Continue;
}