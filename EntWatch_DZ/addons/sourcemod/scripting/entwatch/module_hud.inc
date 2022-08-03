#define EW_MODULE_HUD

#define MAXSHOWHUDITEMS 12
#define MAXSIZESTRINGFORITEM 40
#define TIMEROTORHUD 3

#include <bighud>

//-------------------------------------------------------
// Purpose: Plugin settings
//-------------------------------------------------------
ConVar	g_hCvar_DisplayEnabled,
		g_hCvar_DisplayCooldowns,
		g_hCvar_Admins_See,
		g_hCvar_HUD_Channel,
		g_hCvar_ZM_pry;
//-------------------------------------------------------
// Purpose: Client settings
//-------------------------------------------------------
Handle	g_hCookie_Display		  = null,
		g_hCookie_HudColor		  = null,
		g_hCookie_HudPos		  = null,
		g_hCookie_HudName		  = null;
//-------------------------------------------------------
// Purpose: Plugin Local settings
//-------------------------------------------------------
bool	g_bDispEnabled = true,
		g_bDispCooldowns = true,
		g_bAdminsSee = true,
		g_bZombieNoItemPry = false;

int		g_iHUDChannel = 5;
int		g_iRotorTime = 0;

int		g_iRotation[3][2]; // [0] - Humans, [1] - Zombies, [2] - Admins, [x][0] - count Items, [x][1] - current # list
ArrayList	g_iHItemsArray;
ArrayList	g_iZMItemsArray;

class_ClientSettings_Hud g_CSettings_Hud[MAXPLAYERS+1];

stock void EWM_Hud_OnPluginStart()
{
	g_iHItemsArray = new ArrayList(32);
	g_iZMItemsArray = new ArrayList(32);
	g_hCvar_DisplayEnabled		= CreateConVar("entwatch_display_enable", "1", "Enable/Disable the display.", _, true, 0.0, true, 1.0);
	g_hCvar_DisplayCooldowns	= CreateConVar("entwatch_display_cooldowns", "1", "Show/Hide the cooldowns on the display.", _, true, 0.0, true, 1.0);
	g_hCvar_Admins_See			= CreateConVar("entwatch_admins_see", "1", "Enable/Disable admins see everything Items", _, true, 0.0, true, 1.0);
	g_hCvar_HUD_Channel			= CreateConVar("entwatch_hud_channel", "5", "Change HUD Channel/Group Dynamic channel.", _, true, 0.0, true, 5.0);
	g_hCvar_ZM_pry				= CreateConVar("entwatch_zm_noitem_pry", "0", "Enable/Disable zm pry human Items if zms without items", _, true, 0.0, true, 1.0);
	
	g_bDispEnabled = GetConVarBool(g_hCvar_DisplayEnabled);
	g_bDispCooldowns = GetConVarBool(g_hCvar_DisplayCooldowns);
	g_bAdminsSee = GetConVarBool(g_hCvar_Admins_See);
	g_iHUDChannel = GetConVarInt(g_hCvar_HUD_Channel);
	g_bZombieNoItemPry = GetConVarBool(g_hCvar_ZM_pry);
	
	RegConsoleCmd("sm_hud", EWM_Hud_Command_ToggleHUD);
	RegConsoleCmd("sm_hudname", EWM_Hud_Command_ToggleHUDName);
	RegConsoleCmd("sm_hudpos", EWM_Hud_Command_Hudpos);
	RegConsoleCmd("sm_hudcolor", EWM_Hud_Command_HudColor);
	
	HookConVarChange(g_hCvar_DisplayEnabled, Cvar_HUD_Changed);
	HookConVarChange(g_hCvar_DisplayCooldowns, Cvar_HUD_Changed);
	HookConVarChange(g_hCvar_Admins_See, Cvar_HUD_Changed);
	HookConVarChange(g_hCvar_HUD_Channel, Cvar_HUD_Changed);
	HookConVarChange(g_hCvar_ZM_pry, Cvar_HUD_Changed);
	
	g_hCookie_Display     = RegClientCookie("entwatch_display", "", CookieAccess_Private);
	g_hCookie_HudName     = RegClientCookie("entwatch_hudname", "", CookieAccess_Private);
	g_hCookie_HudColor    = RegClientCookie("entwatch_hudcolor_rgba", "", CookieAccess_Private);
	g_hCookie_HudPos      = RegClientCookie("entwatch_hudpos", "", CookieAccess_Private);
	
	CreateTimer(1.0, EWM_Hud_Timer_DisplayHUD, _, TIMER_REPEAT);
}

public void Cvar_HUD_Changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar==g_hCvar_DisplayEnabled)
		g_bDispEnabled = GetConVarBool(convar);
	else if(convar==g_hCvar_DisplayCooldowns)
		g_bDispCooldowns = GetConVarBool(convar);
	else if(convar==g_hCvar_Admins_See)
		g_bAdminsSee = GetConVarBool(convar);
	else if(convar==g_hCvar_HUD_Channel)
		g_iHUDChannel = GetConVarInt(convar);
	else if(convar==g_hCvar_ZM_pry)
		g_bZombieNoItemPry = GetConVarBool(convar);
}

stock void EWM_Hud_OnClientCookiesCached(int iClient)
{
	char sBuffer_cookie[32];
	
	// Display
	GetClientCookie(iClient, g_hCookie_Display, sBuffer_cookie, sizeof(sBuffer_cookie));
	if (StrEqual(sBuffer_cookie,""))
	{
		SetClientCookie(iClient, g_hCookie_Display, "1");
		strcopy(sBuffer_cookie, sizeof(sBuffer_cookie), "1");
	}
	g_CSettings_Hud[iClient].Display = view_as<bool>(StringToInt(sBuffer_cookie));

	//Hud Names
	GetClientCookie(iClient, g_hCookie_HudName, sBuffer_cookie, sizeof(sBuffer_cookie));
	if (StrEqual(sBuffer_cookie,""))
	{
		SetClientCookie(iClient, g_hCookie_HudName, "1");
		strcopy(sBuffer_cookie, sizeof(sBuffer_cookie), "1");
	}
	g_CSettings_Hud[iClient].Name = view_as<bool>(StringToInt(sBuffer_cookie));
	
	// Colors RBGA
	GetClientCookie(iClient, g_hCookie_HudColor, sBuffer_cookie, sizeof(sBuffer_cookie));
	if (StrEqual(sBuffer_cookie,""))
	{
		Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%i/%i/%i/%i", g_SchemeConfig.Color_HUD[0], g_SchemeConfig.Color_HUD[1], g_SchemeConfig.Color_HUD[2], g_SchemeConfig.Color_HUD[3]);
		SetClientCookie(iClient, g_hCookie_HudColor, sBuffer_cookie);
		g_CSettings_Hud[iClient].Color[0] = g_SchemeConfig.Color_HUD[0];
		g_CSettings_Hud[iClient].Color[1] = g_SchemeConfig.Color_HUD[1];
		g_CSettings_Hud[iClient].Color[2] = g_SchemeConfig.Color_HUD[2];
		g_CSettings_Hud[iClient].Color[3] = g_SchemeConfig.Color_HUD[3];
	}else 
	{
		char Explode_HudColor[4][32];
		ExplodeString(sBuffer_cookie, "/", Explode_HudColor, 4, 32);
		
		int Color_validate = StringToInt(Explode_HudColor[0]);
		if(Color_validate >= 0 && Color_validate <= 255) g_CSettings_Hud[iClient].Color[0] = Color_validate;
			else g_CSettings_Hud[iClient].Color[0] = g_SchemeConfig.Color_HUD[0];
			
		Color_validate = StringToInt(Explode_HudColor[1]);
		if(Color_validate >= 0 && Color_validate <= 255) g_CSettings_Hud[iClient].Color[1] = Color_validate;
			else g_CSettings_Hud[iClient].Color[1] = g_SchemeConfig.Color_HUD[1];
		
		Color_validate = StringToInt(Explode_HudColor[2]);
		if(Color_validate >= 0 && Color_validate <= 255) g_CSettings_Hud[iClient].Color[2] = Color_validate;
			else g_CSettings_Hud[iClient].Color[2] = g_SchemeConfig.Color_HUD[2];
			
		Color_validate = StringToInt(Explode_HudColor[3]);
		if(Color_validate >= 0 && Color_validate <= 255) g_CSettings_Hud[iClient].Color[3] = Color_validate;
			else g_CSettings_Hud[iClient].Color[3] = g_SchemeConfig.Color_HUD[3];
	}

	// Position
	GetClientCookie(iClient, g_hCookie_HudPos, sBuffer_cookie, sizeof(sBuffer_cookie));
	if (StrEqual(sBuffer_cookie,""))
	{
		FormatEx(sBuffer_cookie, sizeof(sBuffer_cookie), "%f/%f", g_SchemeConfig.Pos_HUD_X, g_SchemeConfig.Pos_HUD_Y);
		SetClientCookie(iClient, g_hCookie_HudPos, sBuffer_cookie);
		g_CSettings_Hud[iClient].Pos_X = g_SchemeConfig.Pos_HUD_X;
		g_CSettings_Hud[iClient].Pos_Y = g_SchemeConfig.Pos_HUD_Y;
	}else 
	{
		char Explode_HudPosition[2][32];
		ExplodeString(sBuffer_cookie, "/", Explode_HudPosition, 2, 32);
		
		float Pos_validate = StringToFloat(Explode_HudPosition[0]);
		if((Pos_validate >= 0.0 && Pos_validate <= 1.0) || Pos_validate == -1.0) g_CSettings_Hud[iClient].Pos_X = Pos_validate;
			else g_CSettings_Hud[iClient].Pos_X = g_SchemeConfig.Pos_HUD_X;
			
		Pos_validate = StringToFloat(Explode_HudPosition[1]);
		if((Pos_validate >= 0.0 && Pos_validate <= 1.0) || Pos_validate == -1.0) g_CSettings_Hud[iClient].Pos_Y = Pos_validate;
			else g_CSettings_Hud[iClient].Pos_Y = g_SchemeConfig.Pos_HUD_Y;
	}
}

stock void EWM_Hud_LoadDefaultClientSettings(int iClient)
{
	g_CSettings_Hud[iClient].Display = true;
	g_CSettings_Hud[iClient].Color[0] = g_SchemeConfig.Color_HUD[0];
	g_CSettings_Hud[iClient].Color[1] = g_SchemeConfig.Color_HUD[1];
	g_CSettings_Hud[iClient].Color[2] = g_SchemeConfig.Color_HUD[2];
	g_CSettings_Hud[iClient].Color[3] = g_SchemeConfig.Color_HUD[3];
	g_CSettings_Hud[iClient].Pos_X = g_SchemeConfig.Pos_HUD_X;
	g_CSettings_Hud[iClient].Pos_Y = g_SchemeConfig.Pos_HUD_Y;
}

public void EWM_Hud_OnMapStart()
{
	g_iHItemsArray.Clear();
	g_iZMItemsArray.Clear();
	for(int i = 0; i < 3; i++)
	{
		g_iRotation[i][0] = 0;
		g_iRotation[i][1] = 0;
	}
}

public Action EWM_Hud_Timer_DisplayHUD(Handle timer, int client)
{
	if (g_bDispEnabled && g_bConfigLoaded)
	{
		g_iHItemsArray.Clear();
		g_iZMItemsArray.Clear();
		for(int i = 0; i<g_ItemList.Length; i++)
		{
			class_ItemList ItemTest;
			g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
			if(ItemTest.Hud && ItemTest.OwnerID != INVALID_ENT_REFERENCE && IsValidEdict(ItemTest.WeaponID))
			{
				if(GetClientTeam(ItemTest.OwnerID)==3) g_iHItemsArray.Push(i);
				else if(GetClientTeam(ItemTest.OwnerID)==2) g_iZMItemsArray.Push(i);
			}
		}
		int iCountHItems = g_iHItemsArray.Length;
		int iCountZMItems = g_iZMItemsArray.Length;
		int iCountAItems = iCountHItems + iCountZMItems;
		int iMaxHList = RoundToCeil(float(iCountHItems)/float(MAXSHOWHUDITEMS));
		int iMaxZMList = RoundToCeil(float(iCountZMItems)/float(MAXSHOWHUDITEMS));
		int iMaxAList = RoundToCeil(float(iCountAItems)/float(MAXSHOWHUDITEMS));
		bool bRotor = false;
		g_iRotorTime++;
		if(g_iRotorTime>=TIMEROTORHUD)
		{
			g_iRotorTime = 0;
			bRotor = true;
		}
		if(iCountHItems != g_iRotation[0][0])
		{
			g_iRotation[0][0] = iCountHItems;
			g_iRotation[0][1] = 0;
		}else
		{
			if(bRotor)
			{
				g_iRotation[0][1] += 1;
				if(g_iRotation[0][1] > iMaxHList-1) g_iRotation[0][1] = 0;
			}
		}
		if(iCountZMItems != g_iRotation[1][0])
		{
			g_iRotation[1][0] = iCountZMItems;
			g_iRotation[1][1] = 0;
		}else
		{
			if(bRotor)
			{
				g_iRotation[1][1] += 1;
				if(g_iRotation[1][1] > iMaxZMList-1) g_iRotation[1][1] = 0;
			}
		}
		if(iCountAItems != g_iRotation[2][0])
		{
			g_iRotation[2][0] = iCountAItems;
			g_iRotation[2][1] = 0;
		}else
		{
			if(bRotor)
			{
				g_iRotation[2][1] += 1;
				if(g_iRotation[2][1] > iMaxAList-1) g_iRotation[2][1] = 0;
			}
		}
		char sMes_Humans[1024];
		char sMes_Humans_woname[1024];
		char sMes_Zombies[1024];
		char sMes_Zombies_woname[1024];
		char sMes_Admins[1024];
		char sMes_Admins_woname[1024];
		EWM_Hud_Construct_String(sMes_Humans, sizeof(sMes_Humans), sMes_Humans_woname, sizeof(sMes_Humans_woname), iCountHItems, iMaxHList, 0);
		EWM_Hud_Construct_String(sMes_Zombies, sizeof(sMes_Zombies), sMes_Zombies_woname, sizeof(sMes_Zombies_woname), iCountZMItems, iMaxZMList, 1);
		EWM_Hud_Construct_String(sMes_Admins, sizeof(sMes_Admins), sMes_Admins_woname, sizeof(sMes_Admins_woname), iCountAItems, iMaxAList, 2, iCountHItems);
		
		if(iCountHItems > 0 || iCountZMItems > 0)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				//if(IsClientInGame(i) && !IsFakeClient(i) && g_CSettings_Hud[i].Display && (!IsVoteInProgress() || !IsClientInVotePool(i)) && GetClientMenu(i) == MenuSource_None)
				if(IsClientInGame(i) && !IsFakeClient(i) && g_CSettings_Hud[i].Display && GetClientMenu(i) == MenuSource_None)
				{
					BigHud_SetHudTextParams(g_CSettings_Hud[i].Pos_X, g_CSettings_Hud[i].Pos_Y, 1.1, g_CSettings_Hud[i].Color[0], g_CSettings_Hud[i].Color[1], g_CSettings_Hud[i].Color[2], g_CSettings_Hud[i].Color[3], 0, 0.0, 0.0, 0.0);
					
					if(g_bAdminsSee && g_bIsAdmin[i])
					{
						if(g_CSettings_Hud[i].Name)
						{
							#if defined DYNAMIC_CHANNELS
							BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Admins);
							#else
							BigHud_ShowHudText(i, g_iHUDChannel, sMes_Admins);
							#endif
						}else
						{
							#if defined DYNAMIC_CHANNELS
							BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Admins_woname);
							#else
							BigHud_ShowHudText(i, g_iHUDChannel, sMes_Admins_woname);
							#endif
						}
					}else if((g_bTeamOnly && GetClientTeam(i)==3) || (g_bZombieNoItemPry && iCountZMItems<=0 && GetClientTeam(i)==2))
					{
						if(iCountHItems > 0)
						{
							if(g_CSettings_Hud[i].Name)
							{
								#if defined DYNAMIC_CHANNELS
								BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Humans);
								#else
								BigHud_ShowHudText(i, g_iHUDChannel, sMes_Humans);
								#endif
							}else
							{
								#if defined DYNAMIC_CHANNELS
								BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Humans_woname);
								#else
								BigHud_ShowHudText(i, g_iHUDChannel, sMes_Humans_woname);
								#endif
							}
						}
					}else if(g_bTeamOnly && GetClientTeam(i)==2)
					{
						if(iCountZMItems > 0)
						{
							if(g_CSettings_Hud[i].Name)
							{
								#if defined DYNAMIC_CHANNELS
								BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Zombies);
								#else
								BigHud_ShowHudText(i, g_iHUDChannel, sMes_Zombies);
								#endif
							}else
							{
								#if defined DYNAMIC_CHANNELS
								BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Zombies_woname);
								#else
								BigHud_ShowHudText(i, g_iHUDChannel, sMes_Zombies_woname);
								#endif
							}
						}
					}else
					{
						if(g_CSettings_Hud[i].Name)
						{
							#if defined DYNAMIC_CHANNELS
							BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Admins);
							#else
							BigHud_ShowHudText(i, g_iHUDChannel, sMes_Admins);
							#endif
						}else
						{
							#if defined DYNAMIC_CHANNELS
							BigHud_ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMes_Admins_woname);
							#else
							BigHud_ShowHudText(i, g_iHUDChannel, sMes_Admins_woname);
							#endif
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void EWM_Hud_Construct_String(char[] sResult, int iSizeResult, char[] sResult_woname, int iSizeResult_woname, int iCountItems, int iMaxList, int iType, int iCountHItems = 0)
{
	if(iCountItems > 0)
	{
		char sBuf[MAXSHOWHUDITEMS][MAXSIZESTRINGFORITEM];
		char sBuf_woname[MAXSHOWHUDITEMS][MAXSIZESTRINGFORITEM];
		int iLastIndex = (g_iRotation[iType][1]+1) * MAXSHOWHUDITEMS;
		if(iLastIndex > iCountItems) iLastIndex = iCountItems;
		int iIndex = -1;
		for(int i = g_iRotation[iType][1]*MAXSHOWHUDITEMS; i < iLastIndex; i++)
		{
			iIndex++;
			class_ItemList ItemTest;
			int iFixIndex = 0;
			if(iType==0) iFixIndex = g_iHItemsArray.Get(i);
			else if(iType==1) iFixIndex = g_iZMItemsArray.Get(i);
			else
			{
				if(i < iCountHItems) iFixIndex = g_iHItemsArray.Get(i);
				else iFixIndex = g_iZMItemsArray.Get(i-iCountHItems); 
			}
			g_ItemList.GetArray(iFixIndex, ItemTest, sizeof(ItemTest));
			UpdateTime();
			if(ItemTest.CheckDelay() > 0.0)
			{
				FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[-%d]", ItemTest.ShortName, ItemTest.RoundDelay());
				FormatEx(sBuf[iIndex], sizeof(sBuf[]), "%s: %N", sBuf_woname[iIndex], ItemTest.OwnerID);
			}
			else
			{
				if(g_bDispCooldowns)
				{
					if(ItemTest.LockButton) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[L]", ItemTest.ShortName);
					//else if(ItemTest.CheckWaitTime() > 0) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundWaitTime());
					else
					{
						switch(ItemTest.Mode)
						{
							case 2:
							{
								if (ItemTest.CheckCoolDown() > 0) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
								else FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[R]", ItemTest.ShortName);
							}
							case 3:
							{
								if (ItemTest.Uses < ItemTest.MaxUses) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
								else FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[E]", ItemTest.ShortName);
							}
							case 4:
							{
								if (ItemTest.CheckCoolDown() > 0) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
								else
									if (ItemTest.Uses < ItemTest.MaxUses) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
									else FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[E]", ItemTest.ShortName);
							}
							case 5:
							{
								if (ItemTest.CheckCoolDown() > 0) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
								else FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
							}
							case 6, 7:
							{
								if (ItemTest.MathValue > 0)
								{
									if(ItemTest.CoolDown > 0 && ItemTest.CheckCoolDown() > 0) FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									else FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.MathValue, ItemTest.MathValueMax);
								}
								else FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[E]", ItemTest.ShortName);
							}
							default: FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[+]", ItemTest.ShortName);
						}
					}
					if(ItemTest.LockButton2) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[L]", sBuf_woname[iIndex]);
					else if(ItemTest.CheckWaitTime2() > 0) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", sBuf_woname[iIndex], ItemTest.RoundWaitTime2());
					else
					{
						switch(ItemTest.Mode2)
						{
							case 2:
							{
								if (ItemTest.CheckCoolDown2() > 0) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", sBuf_woname[iIndex], ItemTest.RoundCoolDown2());
								else Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[R]", sBuf_woname[iIndex]);
							}
							case 3:
							{
								if (ItemTest.Uses2 < ItemTest.MaxUses2) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", sBuf_woname[iIndex], ItemTest.Uses2, ItemTest.MaxUses2);
								else Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[E]", sBuf_woname[iIndex]);
							}
							case 4:
							{
								if (ItemTest.CheckCoolDown2() > 0) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", sBuf_woname[iIndex], ItemTest.RoundCoolDown2());
								else
									if (ItemTest.Uses < ItemTest.MaxUses) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", sBuf_woname[iIndex], ItemTest.Uses2, ItemTest.MaxUses2);
									else Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[E]", sBuf_woname[iIndex]);
							}
							case 5:
							{
								if (ItemTest.CheckCoolDown2() > 0) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", sBuf_woname[iIndex], ItemTest.RoundCoolDown2());
								else Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", sBuf_woname[iIndex], ItemTest.Uses2, ItemTest.MaxUses2);
							}
							case 6, 7:
							{
								if (ItemTest.MathValue2 > 0)
								{
									if(ItemTest.CoolDown2 > 0 && ItemTest.CheckCoolDown2() > 0) Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d]", sBuf_woname[iIndex], ItemTest.RoundCoolDown2());
									else Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[%d/%d]", sBuf_woname[iIndex], ItemTest.MathValue2, ItemTest.MathValueMax2);
								}
								else Format(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s[E]", sBuf_woname[iIndex]);
							}
					}
					}
					FormatEx(sBuf[iIndex], sizeof(sBuf[]), "%s: %N", sBuf_woname[iIndex], ItemTest.OwnerID);
				}
				else
				{
					FormatEx(sBuf[iIndex], sizeof(sBuf[]), "%s: %N", ItemTest.ShortName, ItemTest.OwnerID);
					FormatEx(sBuf_woname[iIndex], sizeof(sBuf_woname[]), "%s picked up", ItemTest.ShortName);
				}
			}
		}
		for(int i=0; i <= iIndex; i++)
		{
			StrCat(sResult, iSizeResult, sBuf[i]);
			StrCat(sResult_woname, iSizeResult_woname, sBuf_woname[i]);
			if(i != iIndex)
			{
				StrCat(sResult, iSizeResult, "\n");
				StrCat(sResult_woname, iSizeResult_woname, "\n");
			}else
			{
				if(iMaxList>1)
				{
					char sCurrentList[MAXSIZESTRINGFORITEM];
					FormatEx(sCurrentList, sizeof(sCurrentList), "\n\nList: %i/%i", g_iRotation[iType][1]+1, iMaxList);
					StrCat(sResult, iSizeResult , sCurrentList);
					StrCat(sResult_woname, iSizeResult_woname, sCurrentList);
				}
			}
		}
	}
}

public Action EWM_Hud_Command_ToggleHUD(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (g_CSettings_Hud[iClient].Display)
		{
			CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud", g_SchemeConfig.Color_Disabled, "Disabled");
			g_CSettings_Hud[iClient].Display = false;
			SetClientCookie(iClient, g_hCookie_Display, "0");
		}
		else
		{
			CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud", g_SchemeConfig.Color_Enabled, "Enabled");
			g_CSettings_Hud[iClient].Display = true;
			SetClientCookie(iClient, g_hCookie_Display, "1");
		}
	}
	return Plugin_Handled;
}

public Action EWM_Hud_Command_ToggleHUDName(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (g_CSettings_Hud[iClient].Name)
		{
			CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud Names", g_SchemeConfig.Color_Disabled, "Disabled");
			g_CSettings_Hud[iClient].Name = false;
			SetClientCookie(iClient, g_hCookie_HudName, "0");
		}
		else
		{
			CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud Names", g_SchemeConfig.Color_Enabled, "Enabled");
			g_CSettings_Hud[iClient].Name = true;
			SetClientCookie(iClient, g_hCookie_HudName, "1");
		}
	}
	return Plugin_Handled;
}

public Action EWM_Hud_Command_Hudpos(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (GetCmdArgs() < 2)
		{
			CReplyToCommand(iClient, "%s%t %s%t: sm_hudpos <x> <y>. %t: %.3f %.3f", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Usage", "Default", g_SchemeConfig.Pos_HUD_X, g_SchemeConfig.Pos_HUD_Y);
			return Plugin_Handled;
		}
		char sBuffer[128];
		float HudPosX_validate;
		float HudPosY_validate;
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		HudPosX_validate = StringToFloat(sBuffer);
		
		GetCmdArg(2, sBuffer, sizeof(sBuffer));
		HudPosY_validate = StringToFloat(sBuffer);
		
		if(((HudPosX_validate >= 0.0 && HudPosX_validate <= 1.0) || HudPosX_validate == -1.0) && ((HudPosY_validate >= 0.0 && HudPosY_validate <= 1.0) || HudPosY_validate == -1.0))
		{
			g_CSettings_Hud[iClient].Pos_X = HudPosX_validate;
			g_CSettings_Hud[iClient].Pos_Y = HudPosY_validate;
			
			char sBuffer_cookie[32];
			FormatEx(sBuffer_cookie, sizeof(sBuffer_cookie), "%f/%f", HudPosX_validate, HudPosY_validate);
			SetClientCookie(iClient, g_hCookie_HudPos, sBuffer_cookie);
		} else 
		{
			CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud Position", g_SchemeConfig.Color_Disabled, "Wrong");
			return Plugin_Handled;
		}
		
		CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud Position", g_SchemeConfig.Color_Enabled, "Saved");
	}
	return Plugin_Handled;
}

public Action EWM_Hud_Command_HudColor(int iClient, int iArgs)
{
	if((IsClientConnected(iClient) && IsClientInGame(iClient)))
	{
		if (GetCmdArgs() < 4)
		{
			CReplyToCommand(iClient, "%s%t %s%t: sm_hudcolor <R> <G> <B> <A>. %t: %i %i %i %i", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Usage", "Default", g_SchemeConfig.Color_HUD[0], g_SchemeConfig.Color_HUD[1], g_SchemeConfig.Color_HUD[2], g_SchemeConfig.Color_HUD[3]);
			return Plugin_Handled;
		}
		char sBuffer[128];
		int iColor_validate[4];
		GetCmdArg(1, sBuffer, sizeof(sBuffer));
		iColor_validate[0] = StringToInt(sBuffer);
		
		GetCmdArg(2, sBuffer, sizeof(sBuffer));
		iColor_validate[1] = StringToInt(sBuffer);
		
		GetCmdArg(3, sBuffer, sizeof(sBuffer));
		iColor_validate[2] = StringToInt(sBuffer);
		
		GetCmdArg(4, sBuffer, sizeof(sBuffer));
		iColor_validate[3] = StringToInt(sBuffer);
		
		if(iColor_validate[0] >= 0 && iColor_validate[0] <= 255 && 
			iColor_validate[1] >= 0 && iColor_validate[1] <= 255 && 
			iColor_validate[2] >= 0 && iColor_validate[2] <= 255 && 
			iColor_validate[3] >= 0 && iColor_validate[3] <= 255)
		{
			g_CSettings_Hud[iClient].Color[0] = iColor_validate[0];
			g_CSettings_Hud[iClient].Color[1] = iColor_validate[1];
			g_CSettings_Hud[iClient].Color[2] = iColor_validate[2];
			g_CSettings_Hud[iClient].Color[3] = iColor_validate[3];
			char sBuffer_cookie[32];
			Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%i/%i/%i/%i", iColor_validate[0], iColor_validate[1], iColor_validate[2], iColor_validate[3]);
			SetClientCookie(iClient, g_hCookie_HudColor, sBuffer_cookie);
		} else 
		{
			CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud Color", g_SchemeConfig.Color_Disabled, "Wrong");
			return Plugin_Handled;
		}
		
		CPrintToChat(iClient, "%s%t %s%t %s%t", g_SchemeConfig.Color_Tag, "EW_Tag", g_SchemeConfig.Color_Warning, "Hud Color", g_SchemeConfig.Color_Enabled, "Saved");
	}
	return Plugin_Handled;
}
