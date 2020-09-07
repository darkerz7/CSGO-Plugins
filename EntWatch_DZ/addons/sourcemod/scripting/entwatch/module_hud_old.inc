#define EW_MODULE_HUD

#define MAXSHOWHUDITEMS 10
#define MAXSIZESTRINGFORITEM 64

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

class_ClientSettings_Hud g_CSettings_Hud[MAXPLAYERS+1];

stock void EWM_Hud_OnPluginStart()
{
	g_hCvar_DisplayEnabled		= CreateConVar("entwatch_display_enable", "1", "Enable/Disable the display.", _, true, 0.0, true, 1.0);
	g_hCvar_DisplayCooldowns	= CreateConVar("entwatch_display_cooldowns", "1", "Show/Hide the cooldowns on the display.", _, true, 0.0, true, 1.0);
	g_hCvar_Admins_See			= CreateConVar("entwatch_admins_see", "1", "Enable/Disable admins see everything Items", _, true, 0.0, true, 1.0);
	g_hCvar_HUD_Channel			= CreateConVar("entwatch_hud_channel", "5", "Change HUD Channel/Group Dynamic channel.", _, true, 0.0, true, 5.0);
	g_hCvar_ZM_pry				= CreateConVar("entwatch_zm_noitem_pry", "0", "Enable/Disable zm pry human Items if zms without items", _, true, 0.0, true, 1.0);
	
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
		if(Pos_validate >= 0.0 && Pos_validate <= 1.0) g_CSettings_Hud[iClient].Pos_X = Pos_validate;
			else g_CSettings_Hud[iClient].Pos_X = g_SchemeConfig.Pos_HUD_X;
			
		Pos_validate = StringToFloat(Explode_HudPosition[1]);
		if(Pos_validate >= 0.0 && Pos_validate <= 1.0) g_CSettings_Hud[iClient].Pos_Y = Pos_validate;
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

public Action EWM_Hud_Timer_DisplayHUD(Handle timer, int client)
{
	if (g_bDispEnabled && g_bConfigLoaded)
	{
		char buffer_teamtext_humans[MAXSHOWHUDITEMS][MAXSIZESTRINGFORITEM];
		char buffer_teamtext_zombies[MAXSHOWHUDITEMS][MAXSIZESTRINGFORITEM];
		char buffer_teamtext_humans_withoutname[MAXSHOWHUDITEMS][MAXSIZESTRINGFORITEM];
		char buffer_teamtext_zombies_withoutname[MAXSHOWHUDITEMS][MAXSIZESTRINGFORITEM];
		int iIndexHumans = -1;
		int iIndexZombies = -1;
		char sMessageHumans[1024];
		char sMessageZombies[1024];
		char sMessageAdmins[1024];
		char sMessageHumans_withoutname[1024];
		char sMessageZombies_withoutname[1024];
		char sMessageAdmins_withoutname[1024];
		for(int i = 0; i<g_ItemList.Length; i++)
		{
			class_ItemList ItemTest;
			g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
			if(ItemTest.Hud && ItemTest.OwnerID != INVALID_ENT_REFERENCE && IsValidEdict(ItemTest.WeaponID))
			{
				ItemTest.UpdateTime();
				if(g_bDispCooldowns)
				{
					if(GetClientTeam(ItemTest.OwnerID)==2 && iIndexZombies < MAXSHOWHUDITEMS-1)//ZM
					{
						iIndexZombies++;
						if(ItemTest.CheckDelay() > 0)
						{
							FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[-%d]: %N", ItemTest.ShortName, ItemTest.RoundDelay(), ItemTest.OwnerID);
							FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[-%d]", ItemTest.ShortName, ItemTest.RoundDelay());
						}
						else
						{
							switch(ItemTest.Mode)
							{
								case 2:
								{
									if (ItemTest.CheckCoolDown() > 0)
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[%d]: %N", ItemTest.ShortName, ItemTest.RoundCoolDown(), ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									}
									else
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[R]: %N", ItemTest.ShortName, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[R]", ItemTest.ShortName);
									}
								}
								case 3:
								{
									if (ItemTest.Uses < ItemTest.MaxUses)
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
									}
									else
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[E]: %N", ItemTest.ShortName, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[E]", ItemTest.ShortName);
									}
								}
								case 4:
								{
									if (ItemTest.CheckCoolDown() > 0)
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[%d]: %N", ItemTest.ShortName, ItemTest.RoundCoolDown(), ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									}
									else
										if (ItemTest.Uses < ItemTest.MaxUses)
										{
											FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses, ItemTest.OwnerID);
											FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
										}
										else
										{
											FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[E]: %N", ItemTest.ShortName, ItemTest.OwnerID);
											FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[E]", ItemTest.ShortName);
										}
								}
								case 5:
								{
									if (ItemTest.CheckCoolDown() > 0)
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[%d]: %N", ItemTest.ShortName, ItemTest.RoundCoolDown(), ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									}
									else
									{
										FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
									}
								}
								default:
								{
									FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[N/A]: %N", ItemTest.ShortName, ItemTest.OwnerID);
									FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[N/A]", ItemTest.ShortName);
								}
							}
						}
					}
					else if(GetClientTeam(ItemTest.OwnerID)==3 && iIndexHumans < MAXSHOWHUDITEMS-1)//Humans
					{
						iIndexHumans++;
						if(ItemTest.CheckDelay() > 0)
						{
							FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[-%d]: %N", ItemTest.ShortName, ItemTest.RoundDelay(), ItemTest.OwnerID);
							FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[-%d]", ItemTest.ShortName, ItemTest.RoundDelay());
						}
						else
						{
							switch(ItemTest.Mode)
							{
								case 2:
								{
									if (ItemTest.CheckCoolDown() > 0)
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d]: %N", ItemTest.ShortName, ItemTest.RoundCoolDown(), ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									}
									else
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[R]: %N", ItemTest.ShortName, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[R]", ItemTest.ShortName);
									}
								}
								case 3:
								{
									if (ItemTest.Uses < ItemTest.MaxUses)
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
									}
									else
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[E]: %N", ItemTest.ShortName, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[E]", ItemTest.ShortName);
									}
								}
								case 4:
								{
									if (ItemTest.CheckCoolDown() > 0)
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d]: %N", ItemTest.ShortName, ItemTest.RoundCoolDown(), ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									}
									else
										if (ItemTest.Uses < ItemTest.MaxUses)
										{
											FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses, ItemTest.OwnerID);
											FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
										}
										else
										{
											FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[E]: %N", ItemTest.ShortName, ItemTest.OwnerID);
											FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[E]", ItemTest.ShortName);
										}
								}
								case 5:
								{
									if (ItemTest.CheckCoolDown() > 0)
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d]: %N", ItemTest.ShortName, ItemTest.RoundCoolDown(), ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.RoundCoolDown());
									}
									else
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d/%d]", ItemTest.ShortName, ItemTest.Uses, ItemTest.MaxUses);
									}
								}
								case 6, 7:
								{
									if (ItemTest.MathValue > 0)
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[%d/%d]: %N", ItemTest.ShortName, ItemTest.MathValue, ItemTest.MathValueMax, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[%d]", ItemTest.ShortName, ItemTest.MathValue);
									}
									else
									{
										FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[E]: %N", ItemTest.ShortName, ItemTest.OwnerID);
										FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[E]", ItemTest.ShortName);
									}
								}
								default:
								{
									FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[N/A]: %N", ItemTest.ShortName, ItemTest.OwnerID);
									FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[N/A]", ItemTest.ShortName);
								}
							}
						}
					}
				} else
				{
					if(GetClientTeam(ItemTest.OwnerID)==2 && iIndexZombies < MAXSHOWHUDITEMS-1)//ZM
					{
						iIndexZombies++;
						if(ItemTest.CheckDelay() > 0)
						{
							FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s[-%d]: %N", ItemTest.ShortName, ItemTest.RoundDelay(), ItemTest.OwnerID);
							FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s[-%d]", ItemTest.ShortName, ItemTest.RoundDelay());
						}
						else
						{
							FormatEx(buffer_teamtext_zombies[iIndexZombies], sizeof(buffer_teamtext_zombies[]), "%s: %N", ItemTest.ShortName, ItemTest.OwnerID);
							FormatEx(buffer_teamtext_zombies_withoutname[iIndexZombies], sizeof(buffer_teamtext_zombies_withoutname[]), "%s picked up", ItemTest.ShortName);
						}
					}else if(GetClientTeam(ItemTest.OwnerID)==3 && iIndexHumans < MAXSHOWHUDITEMS-1)//Humans
					{
						iIndexHumans++;
						if(ItemTest.CheckDelay() > 0)
						{
							FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s[-%d]: %N", ItemTest.ShortName, ItemTest.RoundDelay(), ItemTest.OwnerID);
							FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s[-%d]", ItemTest.ShortName, ItemTest.RoundDelay());
						}
						else
						{
							FormatEx(buffer_teamtext_humans[iIndexHumans], sizeof(buffer_teamtext_humans[]), "%s: %N", ItemTest.ShortName, ItemTest.OwnerID);
							FormatEx(buffer_teamtext_humans_withoutname[iIndexHumans], sizeof(buffer_teamtext_humans_withoutname[]), "%s picked up", ItemTest.ShortName);
						}
					}
				}
			}
		}
		if(iIndexZombies>-1)
			for(int i=0; i <= iIndexZombies; i++)
			{
				StrCat(sMessageZombies,sizeof(sMessageZombies),buffer_teamtext_zombies[i]);
				StrCat(sMessageZombies_withoutname,sizeof(sMessageZombies_withoutname),buffer_teamtext_zombies_withoutname[i]);
				if(i!=iIndexZombies)
				{
					StrCat(sMessageZombies,sizeof(sMessageZombies),"\n");
					StrCat(sMessageZombies_withoutname,sizeof(sMessageZombies_withoutname),"\n");
				}
			}
		if(iIndexHumans>-1)
			for(int i=0; i <= iIndexHumans; i++)
			{
				StrCat(sMessageHumans,sizeof(sMessageHumans),buffer_teamtext_humans[i]);
				StrCat(sMessageHumans_withoutname,sizeof(sMessageHumans_withoutname),buffer_teamtext_humans_withoutname[i]);
				if(i!=iIndexHumans)
				{
					StrCat(sMessageHumans,sizeof(sMessageHumans),"\n");
					StrCat(sMessageHumans_withoutname,sizeof(sMessageHumans_withoutname),"\n");
				}
			}
		if(iIndexZombies>-1 || iIndexHumans>-1)
		{
			for(int i=0; i <= iIndexHumans; i++)
			{
				StrCat(sMessageAdmins,sizeof(sMessageAdmins),buffer_teamtext_humans[i]);
				StrCat(sMessageAdmins_withoutname,sizeof(sMessageAdmins_withoutname),buffer_teamtext_humans_withoutname[i]);
				if(i!=iIndexHumans)
				{
					StrCat(sMessageAdmins,sizeof(sMessageAdmins),"\n");
					StrCat(sMessageAdmins_withoutname,sizeof(sMessageAdmins_withoutname),"\n");
				}
			}
			if(iIndexHumans>-1 && iIndexZombies>-1)
			{
				StrCat(sMessageAdmins,sizeof(sMessageAdmins),"\n");
				StrCat(sMessageAdmins_withoutname,sizeof(sMessageAdmins_withoutname),"\n");
			}
			for(int i=0; i <= iIndexZombies; i++)
			{
				StrCat(sMessageAdmins,sizeof(sMessageAdmins),buffer_teamtext_zombies[i]);
				StrCat(sMessageAdmins_withoutname,sizeof(sMessageAdmins_withoutname),buffer_teamtext_zombies_withoutname[i]);
				if(i!=iIndexZombies)
				{
					StrCat(sMessageAdmins,sizeof(sMessageAdmins),"\n");
					StrCat(sMessageAdmins_withoutname,sizeof(sMessageAdmins_withoutname),"\n");
				}
			}
		}
		if(iIndexZombies>-1 || iIndexHumans>-1)
		{
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && g_CSettings_Hud[i].Display && (!IsVoteInProgress() || !IsClientInVotePool(i)) && GetClientMenu(i) == MenuSource_None)
				{
					SetHudTextParams(g_CSettings_Hud[i].Pos_X, g_CSettings_Hud[i].Pos_Y, 1.1, g_CSettings_Hud[i].Color[0], g_CSettings_Hud[i].Color[1], g_CSettings_Hud[i].Color[2], g_CSettings_Hud[i].Color[3], 0, 0.0, 0.0, 0.0);
					
					if(g_bAdminsSee && g_bIsAdmin[i])
					{
						if(g_CSettings_Hud[i].Name)
						{
							#if defined DYNAMIC_CHANNELS
							ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageAdmins);
							#else
							ShowHudText(i, g_iHUDChannel, sMessageAdmins);
							#endif
						}else
						{
							#if defined DYNAMIC_CHANNELS
							ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageAdmins_withoutname);
							#else
							ShowHudText(i, g_iHUDChannel, sMessageAdmins_withoutname);
							#endif
						}
					}else if((g_bTeamOnly && GetClientTeam(i)==3) || (g_bZombieNoItemPry && iIndexZombies<=-1 && GetClientTeam(i)==2))
					{
						if(iIndexHumans>-1)
						{
							if(g_CSettings_Hud[i].Name)
							{
								#if defined DYNAMIC_CHANNELS
								ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageHumans);
								#else
								ShowHudText(i, g_iHUDChannel, sMessageHumans);
								#endif
							}else
							{
								#if defined DYNAMIC_CHANNELS
								ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageHumans_withoutname);
								#else
								ShowHudText(i, g_iHUDChannel, sMessageHumans_withoutname);
								#endif
							}
						}
					}else if(g_bTeamOnly && GetClientTeam(i)==2)
					{
						if(iIndexZombies>-1)
						{
							if(g_CSettings_Hud[i].Name)
							{
								#if defined DYNAMIC_CHANNELS
								ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageZombies);
								#else
								ShowHudText(i, g_iHUDChannel, sMessageZombies);
								#endif
							}else
							{
								#if defined DYNAMIC_CHANNELS
								ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageZombies_withoutname);
								#else
								ShowHudText(i, g_iHUDChannel, sMessageZombies_withoutname);
								#endif
							}
						}
					}else
					{
						if(g_CSettings_Hud[i].Name)
						{
							#if defined DYNAMIC_CHANNELS
							ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageAdmins);
							#else
							ShowHudText(i, g_iHUDChannel, sMessageAdmins);
							#endif
						}else
						{
							#if defined DYNAMIC_CHANNELS
							ShowHudText(i, GetDynamicChannel(g_iHUDChannel), sMessageAdmins_withoutname);
							#else
							ShowHudText(i, g_iHUDChannel, sMessageAdmins_withoutname);
							#endif
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
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
		
		if(HudPosX_validate >= 0.0 && HudPosY_validate >= 0.0 && HudPosX_validate <= 1.0 && HudPosY_validate <= 1.0)
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
