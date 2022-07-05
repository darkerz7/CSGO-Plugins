#define EW_MODULE_NATIVES

#tryinclude <EntWatch>

bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle hThis, bool bLate, char[] sError, int iErr_max)
{
	#if defined EW_MODULE_EBAN
	CreateNative("EntWatch_IsClientBanned", EWM_Natives_Native_IsClientBanned);
	CreateNative("EntWatch_BanClient", EWM_Natives_Native_BanClient);
	CreateNative("EntWatch_UnbanClient", EWM_Natives_Native_UnbanClient);
	#endif
	#if defined EW_MODULE_HUD
	CreateNative("EntWatch_GetHudSettings", EWM_Natives_Native_GetHudSettings);
	CreateNative("EntWatch_SetHudDisplay", EWM_Natives_Native_SetHudDisplay);
	CreateNative("EntWatch_SetHudName", EWM_Natives_Native_SetHudName);
	CreateNative("EntWatch_SetHudPosition", EWM_Natives_Native_SetHudPosition);
	CreateNative("EntWatch_SetHudColors", EWM_Natives_Native_SetHudColors);
	CreateNative("EntWatch_GetHudDefault", EWM_Natives_Native_GetHudDefault);
	#endif
	CreateNative("EntWatch_IsSpecialItem", EWM_Natives_Native_IsSpecialItem);
	CreateNative("EntWatch_HasSpecialItem", EWM_Natives_Native_HasSpecialItem);
	#if defined EW_MODULE_HIGHLIGHT
	CreateNative("EntWatch_SetHLWeapon", EWM_Natives_Native_SetHLWeapon);
	CreateNative("EntWatch_SetHLPlayer", EWM_Natives_Native_SetHLPlayer);
	CreateNative("EntWatch_SetHLWeaponOne", EWM_Natives_Native_SetHLWeaponOne);
	CreateNative("EntWatch_SetHLPlayerOne", EWM_Natives_Native_SetHLPlayerOne);
	CreateNative("EntWatch_RemoveHLWeaponOne", EWM_Natives_Native_RemoveHLWeaponOne);
	CreateNative("EntWatch_RemoveHLPlayerOne", EWM_Natives_Native_RemoveHLPlayerOne);
	#endif

	RegPluginLibrary("EntWatch");

	g_bLateLoad = bLate;

	return APLRes_Success;
}

stock void EWM_Natives_OnPluginStart()
{
	if (g_bLateLoad)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i)) continue;
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}
}

#if defined EW_MODULE_EBAN
public int EWM_Natives_Native_IsClientBanned(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client");
		return false;
	}

	if(g_EbanClients[iClient].Banned)
	{
		SetNativeCellRef(2, g_EbanClients[iClient].TimeStamp_Issued);
		SetNativeCellRef(3, g_EbanClients[iClient].Duration);
		SetNativeString(4, g_EbanClients[iClient].Reason, 64, true);
		return true;
	}

	return false;
}

public int EWM_Natives_Native_BanClient(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);
	int iAdmin = GetNativeCell(2);
	int iDuration = GetNativeCell(3);
	char sReason[64];
	GetNativeString(4, sReason, sizeof(sReason));

	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	
	if(!IsValidClient(iAdmin) || !IsClientConnected(iAdmin)) iAdmin = 0;

	EWM_Eban_BanClient(iClient, iAdmin, iDuration, sReason);
	return true;
}

public int EWM_Natives_Native_UnbanClient(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);
	int iAdmin = GetNativeCell(2);
	char sReason[64];
	GetNativeString(3, sReason, sizeof(sReason));

	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	
	if(!IsValidClient(iAdmin) || !IsClientConnected(iAdmin)) iAdmin = 0;

	EWM_Eban_UnBanClient(iClient, iAdmin, sReason);
	return true;
}
#endif

#if defined EW_MODULE_HUD
public int EWM_Natives_Native_GetHudSettings(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client cookies are not yet loaded");
		class_ClientSettings_Hud cDefault;
		cDefault.Display = true;
		cDefault.Color[0] = g_SchemeConfig.Color_HUD[0];
		cDefault.Color[1] = g_SchemeConfig.Color_HUD[1];
		cDefault.Color[2] = g_SchemeConfig.Color_HUD[2];
		cDefault.Color[3] = g_SchemeConfig.Color_HUD[3];
		cDefault.Pos_X = g_SchemeConfig.Pos_HUD_X;
		cDefault.Pos_Y = g_SchemeConfig.Pos_HUD_Y;
		cDefault.Name = true;
		SetNativeArray(2, cDefault, sizeof(cDefault));
		return false;
	}
	SetNativeArray(2, g_CSettings_Hud[iClient], sizeof(g_CSettings_Hud[]));
	return true;
}

public int EWM_Natives_Native_SetHudDisplay(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client cookies are not yet loaded");
		return false;
	}
	
	int iNativeDisplay = GetNativeCell(2);
	if(iNativeDisplay == 0)
	{
		if(g_CSettings_Hud[iClient].Display == true)
		{
			g_CSettings_Hud[iClient].Display = false;
			SetClientCookie(iClient, g_hCookie_Display, "0");
		}
	}else
	{
		if(g_CSettings_Hud[iClient].Display == false)
		{
			g_CSettings_Hud[iClient].Display = true;
			SetClientCookie(iClient, g_hCookie_Display, "1");
		}
	}
	return true;
}

public int EWM_Natives_Native_SetHudName(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client cookies are not yet loaded");
		return false;
	}
	
	int iNativeName = GetNativeCell(2);
	if(iNativeName == 0)
	{
		if(g_CSettings_Hud[iClient].Name == true)
		{
			g_CSettings_Hud[iClient].Name = false;
			SetClientCookie(iClient, g_hCookie_HudName, "0");
		}
	}else
	{
		if(g_CSettings_Hud[iClient].Name == false)
		{
			g_CSettings_Hud[iClient].Name = true;
			SetClientCookie(iClient, g_hCookie_HudName, "1");
		}
	}
	return true;
}

public int EWM_Natives_Native_SetHudPosition(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client cookies are not yet loaded");
		return false;
	}
	
	float fNativePosX = view_as<float>(GetNativeCell(2));
	float fNativePosY = view_as<float>(GetNativeCell(3));
	
	if(fNativePosX < 0.0 || fNativePosY < 0.0 || fNativePosX > 1.0 || fNativePosY > 1.0)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid Position");
		return false;
	}
	
	g_CSettings_Hud[iClient].Pos_X = fNativePosX;
	g_CSettings_Hud[iClient].Pos_Y = fNativePosY;
	
	char sBuffer_cookie[32];
	FormatEx(sBuffer_cookie, sizeof(sBuffer_cookie), "%f/%f", fNativePosX, fNativePosY);
	SetClientCookie(iClient, g_hCookie_HudPos, sBuffer_cookie);
	return true;
}

public int EWM_Natives_Native_SetHudColors(Handle hPlugin, int iArgC)
{
	int iClient = GetNativeCell(1);

	if(!IsValidClient(iClient) || !AreClientCookiesCached(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid client or client cookies are not yet loaded");
		return false;
	}
	
	int iNativeColor[4];
	if(GetNativeArray(2, iNativeColor, 4) != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid Colors Array");
		return false;
	}
	
	if(iNativeColor[0] < 0 || iNativeColor[0] > 255 || 
		iNativeColor[1] < 0 || iNativeColor[1] > 255 ||
		iNativeColor[2] < 0 || iNativeColor[2] > 255 ||
		iNativeColor[3] < 0 || iNativeColor[3] > 255)
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid Colors");
		return false;
	}
	
	g_CSettings_Hud[iClient].Color[0] = iNativeColor[0];
	g_CSettings_Hud[iClient].Color[1] = iNativeColor[1];
	g_CSettings_Hud[iClient].Color[2] = iNativeColor[2];
	g_CSettings_Hud[iClient].Color[3] = iNativeColor[3];
	
	char sBuffer_cookie[32];
	Format(sBuffer_cookie, sizeof(sBuffer_cookie), "%i/%i/%i/%i", iNativeColor[0], iNativeColor[1], iNativeColor[2], iNativeColor[3]);
	SetClientCookie(iClient, g_hCookie_HudColor, sBuffer_cookie);
	return true;
}

public int EWM_Natives_Native_GetHudDefault(Handle hPlugin, int iArgC)
{
	class_ClientSettings_Hud cDefault;
	cDefault.Display = true;
	cDefault.Color[0] = g_SchemeConfig.Color_HUD[0];
	cDefault.Color[1] = g_SchemeConfig.Color_HUD[1];
	cDefault.Color[2] = g_SchemeConfig.Color_HUD[2];
	cDefault.Color[3] = g_SchemeConfig.Color_HUD[3];
	cDefault.Pos_X = g_SchemeConfig.Pos_HUD_X;
	cDefault.Pos_Y = g_SchemeConfig.Pos_HUD_Y;
	cDefault.Name = true;
	
	SetNativeArray(1, cDefault, sizeof(cDefault));
	return true;
}
#endif

#if defined EW_MODULE_HIGHLIGHT
public int EWM_Natives_Native_SetHLWeapon(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iCount = GetNativeCell(1);
	int iClients[MAXPLAYERS+1] = {-1,...};
	GetNativeArray(2,iClients,iCount);
	for(int i = 0; i < iCount; i++)
	{
		if (!IsValidClient(iClients[i]))
		{
			ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient Num:%d", i);
			return false;
		}
	}
	for(int i = 0; i < iCount; i++) g_bHL_Privilege_Weapon[iClients[i]] = true;
	return true;
}

public int EWM_Natives_Native_SetHLPlayer(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iCount = GetNativeCell(1);
	int iClients[MAXPLAYERS+1] = {-1,...};
	GetNativeArray(2,iClients,iCount);
	for(int i = 0; i < iCount; i++)
	{
		if (!IsValidClient(iClients[i]))
		{
			ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient Num:%d", i);
			return false;
		}
	}
	for(int i = 0; i < iCount; i++) g_bHL_Privilege_Player[iClients[i]] = true;
	return true;
}

public int EWM_Natives_Native_SetHLWeaponOne(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	g_bHL_Privilege_Weapon[iClient] = true;
	return true;
}

public int EWM_Natives_Native_SetHLPlayerOne(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	g_bHL_Privilege_Player[iClient] = true;
	return true;
}

public int EWM_Natives_Native_RemoveHLWeaponOne(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	g_bHL_Privilege_Weapon[iClient] = false;
	return true;
}

public int EWM_Natives_Native_RemoveHLPlayerOne(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}
	g_bHL_Privilege_Player[iClient] = false;
	return true;
}
#endif

public int EWM_Natives_Native_IsSpecialItem(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	
	int iEntity = GetNativeCell(1);
	for(int i = 0; i<g_ItemList.Length; i++)
	{
		class_ItemList ItemTest;
		g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
		for(int j = 0; j < ItemTest.ButtonsArray.Length; j++)
		{
			if(ItemTest.ButtonsArray.Get(j) == iEntity) return true;
		}
	}

	return false;
}

public int EWM_Natives_Native_HasSpecialItem(Handle hPlugin, int iArgC)
{
	if (!g_bConfigLoaded) return false;
	int iClient = GetNativeCell(1);

	if (!IsValidClient(iClient))
	{
		ThrowNativeError(SP_ERROR_PARAM, "Invalid iClient");
		return false;
	}

	for(int i = 0; i<g_ItemList.Length; i++)
	{
		class_ItemList ItemTest;
		g_ItemList.GetArray(i, ItemTest, sizeof(ItemTest));
		if(ItemTest.WeaponID != INVALID_ENT_REFERENCE)
			if(ItemTest.OwnerID == iClient) return true;
	}

	return false;
}