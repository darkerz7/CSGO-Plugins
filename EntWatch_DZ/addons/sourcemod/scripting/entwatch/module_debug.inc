#define EW_MODULE_DEBUG

stock void EWM_Debug_OnPluginStart()
{
	RegAdminCmd("sm_ewdebugconfig", Command_DebugConfig, ADMFLAG_CONFIG);
	RegAdminCmd("sm_ewdebugarray", Command_DebugArray, ADMFLAG_CONFIG);
	RegAdminCmd("sm_ewdebugscheme", Command_DebugScheme, ADMFLAG_CONFIG);
}

public Action Command_DebugConfig(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		for(int i = 0; i<g_ItemConfig.Length; i++)
		{
			class_ItemConfig ItemTest;
			g_ItemConfig.GetArray(i, ItemTest, sizeof(ItemTest));
			PrintToChat(iClient, "[DEBUG] Name:%s SN:%s Color:%s BC:%s FN:%s", ItemTest.Name, ItemTest.ShortName, ItemTest.Color, ItemTest.ButtonClass, ItemTest.FilterName);
			PrintToChat(iClient, "[DEBUG] |-BlockPickup:%i AllowTransfer:%i ForceDrop: %i Chat:%i Hud: %i", ItemTest.BlockPickup, ItemTest.AllowTransfer, ItemTest.ForceDrop, ItemTest.Chat, ItemTest.Hud);
			PrintToChat(iClient, "[DEBUG] |-HammerID:%i Mode:%i MaxUses:%i CoolDown:%i ButtonID:%i", ItemTest.HammerID, ItemTest.Mode, ItemTest.MaxUses, ItemTest.CoolDown, ItemTest.ButtonID);
			#if defined EW_MODULE_GLOW
			PrintToChat(iClient, "[DEBUG] |-Glow Red:%i Green:%i Blue:%i", ItemTest.GlowColor[0], ItemTest.GlowColor[1], ItemTest.GlowColor[2]);
			#endif
		}
	}
}

public Action Command_DebugArray(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		PrintToChat(iClient, "[DEBUG] Count Current Items: %i", g_ItemList.Length);
		for(int i = 0; i<g_ItemList.Length; i++)
		{
			class_ItemList ItemTest;
			g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
			PrintToChat(iClient, "[DEBUG] Name:%s SN:%s Color:%s BC:%s FN:%s", ItemTest.Name, ItemTest.ShortName, ItemTest.Color, ItemTest.ButtonClass, ItemTest.FilterName);
			PrintToChat(iClient, "[DEBUG] |-BlockPickup:%i AllowTransfer:%i ForceDrop: %i Chat:%i Hud: %i", ItemTest.BlockPickup, ItemTest.AllowTransfer, ItemTest.ForceDrop, ItemTest.Chat, ItemTest.Hud);
			PrintToChat(iClient, "[DEBUG] |-HammerID:%i Mode:%i MaxUses:%i CoolDown:%i ButtonID:%i", ItemTest.HammerID, ItemTest.Mode, ItemTest.MaxUses, ItemTest.CoolDown, ItemTest.ButtonID);
			PrintToChat(iClient, "[DEBUG] |-Uses:%i CoolDownTime:%i Delay:%i", ItemTest.Uses, ItemTest.CoolDownTime, ItemTest.Delay);
			char Buttons[128];
			for(int j = 0; j<ItemTest.ButtonsArray.Length; j++)
				Format(Buttons, sizeof(Buttons), "%s %i", Buttons,ItemTest.ButtonsArray.Get(j));
			PrintToChat(iClient, "[DEBUG] |-OwnerID:%i WeaponID:%i ButtonIDs:%s", ItemTest.OwnerID, ItemTest.WeaponID, Buttons);
			#if defined EW_MODULE_GLOW
			PrintToChat(iClient, "[DEBUG] |-Glow Red:%i Green:%i Blue:%i Ent:%i", ItemTest.GlowColor[0], ItemTest.GlowColor[1], ItemTest.GlowColor[2], ItemTest.GlowEnt);
			#endif
		}
	}
}

public Action Command_DebugScheme(int iClient, int iArgs)
{
	if(IsClientConnected(iClient) && IsClientInGame(iClient))
	{
		CPrintToChat(iClient, "%s[DEBUG] %sName %sSteamID %sUse %sPickup %sDrop %sDisconnect %sDeath %sWarning", g_SchemeConfig.Color_Tag, g_SchemeConfig.Color_Name, g_SchemeConfig.Color_SteamID, g_SchemeConfig.Color_Use, g_SchemeConfig.Color_Pickup, g_SchemeConfig.Color_Drop, g_SchemeConfig.Color_Disconnect, g_SchemeConfig.Color_Death, g_SchemeConfig.Color_Warning);
		#if defined EW_MODULE_HUD
		CPrintToChat(iClient, "%s[DEBUG] %sColor: R-%i G-%i B-%i A-%i Pos: X-%.4f Y-%.4f",g_SchemeConfig.Color_Tag, g_SchemeConfig.Color_Warning, g_SchemeConfig.Color_HUD[0], g_SchemeConfig.Color_HUD[1], g_SchemeConfig.Color_HUD[2], g_SchemeConfig.Color_HUD[3], g_SchemeConfig.Pos_HUD_X, g_SchemeConfig.Pos_HUD_Y);
		#endif
	}
}